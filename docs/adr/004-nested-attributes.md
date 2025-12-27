# ADR-004: ネストされた属性による一括保存

## ステータス

**承認済み** (2025-12-25)

## コンテキスト

取引（SimpleTransaction）と商品（SimpleTransactionItem）の保存方法を決定する必要があった。取引は1件の商品を持つのではなく、複数の商品を含むため、これらをどのように一括で保存するかが課題だった。

### 要件

- 取引と商品を同時に保存できること
- トランザクションの整合性を保つこと
- コントローラーのコードをシンプルに保つこと
- バリデーションを適切に行えること

### 検討時の制約

- Rails の ActiveRecord を最大限活用したい
- データベースのトランザクション機能を活用したい
- テストしやすいコードにしたい

## 決定

**Rails の `accepts_nested_attributes_for`** を使用して、ネストされた属性による一括保存を採用する。

### 実装方法

```ruby
class SimpleTransaction < ApplicationRecord
  has_many :simple_transaction_items, dependent: :destroy

  # ネストされた属性を受け入れる
  accepts_nested_attributes_for :simple_transaction_items,
                                allow_destroy: true,
                                reject_if: :all_blank

  validates :amount, presence: true, numericality: { greater_than: 0 }
end
```

### 採用理由

1. **トランザクションの自動管理**
   - Rails が自動的にトランザクションで保存
   - 親（取引）と子（商品）の整合性を保証
   - ロールバック処理も自動

2. **シンプルなコントローラー**
   - 1回の save で親子を一括保存
   - 複雑なループ処理が不要
   - コードの可読性が向上

3. **バリデーションの統一**
   - 親子のバリデーションを一括実行
   - エラーメッセージも統一的に取得可能
   - valid? メソッドで全体をチェック

4. **フォームとの親和性**
   - fields_for ヘルパーと自然に統合
   - HTML フォームから直接マッピング可能
   - JavaScript との連携も容易

5. **Rails の標準機能**
   - Rails の標準的なパターン
   - ドキュメントが豊富
   - コミュニティでの知見が多い

## 結果

### ポジティブな影響

- **コードのシンプル化**
  ```ruby
  # コントローラーが非常にシンプル
  def create
    @simple_transaction = SimpleTransaction.new(transaction_params)

    if @simple_transaction.save
      redirect_to @simple_transaction
    else
      render :new
    end
  end
  ```

- **データ整合性の保証**
  - トランザクション内で保存されるため、中途半端な状態にならない
  - ロールバック時も自動的に全て戻る

- **バリデーションの統一**
  ```ruby
  # 親子のバリデーションを一括チェック
  @simple_transaction.valid?
  @simple_transaction.errors.full_messages
  # => ["Amount must be greater than 0", "Items item name can't be blank"]
  ```

- **更新・削除の容易さ**
  ```ruby
  # 既存商品の更新
  params = {
    simple_transaction: {
      amount: 15000,
      simple_transaction_items_attributes: [
        { id: 1, item_name: '更新商品', item_count: 3, item_price: 5000 },
        { id: 2, _destroy: true }  # 削除
      ]
    }
  }
  ```

### ネガティブな影響

- **複雑なバリデーションの実装が難しい**
  - カスタムバリデーションが必要な場合、やや複雑になる
  - 例: 商品の合計金額と取引金額の整合性チェック

- **パラメーター構造の制約**
  - フロントエンドから特定の構造でパラメーターを送る必要がある
  - API設計時に考慮が必要

- **デバッグの複雑さ**
  - エラーがどこで発生したか分かりにくい場合がある
  - ログの詳細化が必要

### 中立的な影響

- **学習コスト**
  - accepts_nested_attributes_for の仕組みを理解する必要がある
  - 但し、一度理解すれば応用が効く

## 代替案

### 案1: 手動でのトランザクション管理

**実装例**:
```ruby
def create
  ActiveRecord::Base.transaction do
    @transaction = SimpleTransaction.create!(transaction_params)

    items_params.each do |item_params|
      @transaction.simple_transaction_items.create!(item_params)
    end
  end
end
```

**メリット**:
- トランザクションの範囲を明示的に制御
- 柔軟な処理が可能
- デバッグしやすい

**デメリット**:
- コードが冗長になる
- バリデーションの統一管理が難しい
- エラーハンドリングが複雑

**却下理由**:
- Rails の標準機能を使わないのは非効率
- コードが複雑になる
- テストが書きにくい

### 案2: サービスオブジェクトでの管理

**実装例**:
```ruby
class TransactionCreateService
  def execute(amount:, items:)
    ActiveRecord::Base.transaction do
      transaction = SimpleTransaction.create!(amount: amount)

      items.each do |item|
        transaction.simple_transaction_items.create!(item)
      end

      transaction
    end
  end
end
```

**メリット**:
- ビジネスロジックを分離
- 複雑な処理も対応可能
- テストしやすい

**デメリット**:
- 小規模プロジェクトには過剰
- コード量が増える
- Rails の標準パターンから外れる

**却下理由**:
- 本プロジェクトの規模では過剰設計
- accepts_nested_attributes_for で十分対応可能
- シンプルさを重視

### 案3: 別々に保存（トランザクションなし）

**実装例**:
```ruby
def create
  @transaction = SimpleTransaction.create!(transaction_params)

  items_params.each do |item_params|
    @transaction.simple_transaction_items.create(item_params)
  end
end
```

**メリット**:
- コードが非常にシンプル
- 実装が容易

**デメリット**:
- データの整合性が保証されない
- 商品の作成が失敗しても取引は残る
- ロールバック処理が複雑

**却下理由**:
- データ整合性が保証されない
- 本番環境での使用に不適切
- 予期しないデータ状態が発生する可能性

## 実装詳細

### モデル定義

```ruby
class SimpleTransaction < ApplicationRecord
  has_many :simple_transaction_items, dependent: :destroy

  accepts_nested_attributes_for :simple_transaction_items,
                                allow_destroy: true,
                                reject_if: :all_blank

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :registration_datetime, presence: true
  validates :status, presence: true, inclusion: { in: %w[active cancelled deleted] }
end

class SimpleTransactionItem < ApplicationRecord
  belongs_to :simple_transaction

  validates :item_name, presence: true, length: { maximum: 255 }
  validates :item_count, presence: true, numericality: { greater_than: 0, less_than: 100000 }
  validates :item_price, presence: true, numericality: { greater_than: 0 }
end
```

### Strong Parameters

```ruby
def transaction_params
  params.require(:simple_transaction).permit(
    :amount,
    simple_transaction_items_attributes: [
      :id,          # 更新時に必要
      :item_name,
      :item_count,
      :item_price,
      :_destroy     # 削除フラグ
    ]
  )
end
```

### ビュー（フォーム）

```erb
<%= form_with model: @simple_transaction, local: true do |f| %>
  <%= f.number_field :amount %>

  <%= f.fields_for :simple_transaction_items do |item_form| %>
    <%= item_form.text_field :item_name %>
    <%= item_form.number_field :item_count %>
    <%= item_form.number_field :item_price %>
    <%= item_form.check_box :_destroy %>
  <% end %>

  <%= f.submit %>
<% end %>
```

### JavaScript での動的追加

```javascript
// 商品行を動的に追加
function addItem() {
  const newIndex = new Date().getTime();
  const template = `
    <input name="simple_transaction[simple_transaction_items_attributes][${newIndex}][item_name]" />
    <input name="simple_transaction[simple_transaction_items_attributes][${newIndex}][item_count]" type="number" />
    <input name="simple_transaction[simple_transaction_items_attributes][${newIndex}][item_price]" type="number" />
  `;
  // DOM に追加
}
```

## 注意点とベストプラクティス

### 1. reject_if オプション

```ruby
# 空白の属性を無視
accepts_nested_attributes_for :simple_transaction_items,
                              reject_if: :all_blank

# カスタム条件
accepts_nested_attributes_for :simple_transaction_items,
                              reject_if: ->(attributes) { attributes['item_name'].blank? }
```

### 2. limit オプション

```ruby
# 作成できる子レコードの上限を設定
accepts_nested_attributes_for :simple_transaction_items,
                              limit: 10
```

### 3. エラーハンドリング

```ruby
if @simple_transaction.save
  # 成功
else
  # @simple_transaction.errors には親子のエラーがすべて含まれる
  @simple_transaction.errors.full_messages.each do |message|
    puts message
  end
end
```

## 参考資料

- [Rails Guides: Nested Attributes](https://guides.rubyonrails.org/form_helpers.html#nested-forms)
- [API Documentation: accepts_nested_attributes_for](https://api.rubyonrails.org/classes/ActiveRecord/NestedAttributes/ClassMethods.html)
- [データベース設計](../architecture/database.md)

## 関連ADR

- [ADR-001: PostgreSQL の採用](001-database-choice.md) - トランザクション機能を活用
- [ADR-005: ステータスによる論理削除](005-logical-delete.md) - 削除処理との関連
