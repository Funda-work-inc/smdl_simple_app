# ADR-005: ステータスによる論理削除

## ステータス

**承認済み** (2025-12-25)

## コンテキスト

取引（SimpleTransaction）の削除方法を決定する必要があった。特に、削除した取引の履歴を保持するか、完全に削除（物理削除）するかを検討する必要があった。

### 要件

- 削除した取引の履歴を保持できること
- API呼び出しログとの関連を維持できること
- 管理者画面で削除済み取引を確認できること
- 誤った削除からの復旧が可能であること

### 検討時の制約

- 一度削除した取引を復元したい場合がある
- 監査目的で削除履歴を残す必要がある
- API呼び出しログが孤立しないようにしたい

## 決定

**ステータスカラムを使用した論理削除** を採用する。

### ステータスの定義

取引のステータスとして以下の3つを定義：

- **active**: 有効な取引（デフォルト）
- **cancelled**: キャンセルされた取引
- **deleted**: 削除された取引

### 削除処理

```ruby
# 物理削除ではなく、ステータスを更新
def destroy
  @simple_transaction = SimpleTransaction.find(params[:id])
  @simple_transaction.update!(status: 'deleted')
  redirect_to admin_simple_transactions_path, notice: '取引を削除しました'
end

# キャンセル処理
def cancel
  @simple_transaction = SimpleTransaction.find(params[:id])
  @simple_transaction.update!(status: 'cancelled')
  redirect_to admin_simple_transaction_path(@simple_transaction), notice: '取引をキャンセルしました'
end
```

### 採用理由

1. **データの保全**
   - 削除した取引のデータが完全に残る
   - いつでも過去の取引を参照可能
   - 監査証跡として機能

2. **関連データの保護**
   - API呼び出しログが孤立しない
   - 外部キーの整合性を維持
   - 商品情報も保持される

3. **復元の容易さ**
   - ステータスを戻すだけで復元可能
   - 誤削除からの回復が簡単
   - データの再入力が不要

4. **柔軟なフィルタリング**
   - 有効な取引のみ表示が容易
   - 削除済み取引も必要に応じて表示
   - ステータスごとの集計が可能

5. **監査要件への対応**
   - いつ削除されたかを記録可能（updated_at）
   - 削除理由を別カラムで記録可能（将来的な拡張）
   - 監査ログとして機能

## 結果

### ポジティブな影響

- **データ保全**
  ```ruby
  # 削除後もデータは残る
  SimpleTransaction.find_by(status: 'deleted')
  # => #<SimpleTransaction id: 1, amount: 10000, status: "deleted", ...>
  ```

- **復元が容易**
  ```ruby
  # ステータスを戻すだけで復元
  transaction.update!(status: 'active')
  ```

- **API ログの整合性**
  ```ruby
  # 削除後も API ログとの関連は維持
  ApiCallLog.where(simple_transaction_id: 1)
  # => [#<ApiCallLog id: 1, simple_transaction_id: 1, ...>]
  ```

- **柔軟な表示制御**
  ```ruby
  # 有効な取引のみ表示
  SimpleTransaction.where(status: 'active')

  # すべての取引を表示（削除済み含む）
  SimpleTransaction.all

  # 削除済み取引のみ表示
  SimpleTransaction.where(status: 'deleted')
  ```

- **統計・分析への活用**
  ```ruby
  # 削除された取引の傾向分析
  SimpleTransaction.where(status: 'deleted')
    .group_by_day(:updated_at)
    .count

  # キャンセル率の計算
  total = SimpleTransaction.count
  cancelled = SimpleTransaction.where(status: 'cancelled').count
  cancel_rate = (cancelled.to_f / total * 100).round(2)
  ```

### ネガティブな影響

- **データ量の増加**
  - 削除してもレコードが残るため、データベースサイズが増加
  - 定期的なアーカイブやクリーンアップが必要

- **クエリの複雑化**
  - 有効な取引のみを対象とする場合、WHERE句が必要
  - デフォルトスコープを使う場合の注意が必要

- **ディスク容量**
  - 長期間運用すると、削除済みレコードが蓄積
  - ストレージコストの増加

- **パフォーマンス**
  - テーブルサイズが大きくなると、クエリ速度が低下する可能性
  - インデックスの最適化が重要

### 中立的な影響

- **明示的なフィルタリング**
  - 常に status を意識する必要がある
  - デフォルトスコープの設定を検討

## 代替案

### 案1: 物理削除（ハードデリート）

**実装例**:
```ruby
def destroy
  @simple_transaction = SimpleTransaction.find(params[:id])
  @simple_transaction.destroy!
  redirect_to admin_simple_transactions_path
end
```

**メリット**:
- データベースサイズが小さくなる
- クエリがシンプル
- ディスク容量の節約

**デメリット**:
- データが完全に失われる
- 復元が不可能
- API ログが孤立する
- 監査証跡が残らない

**却下理由**:
- データ保全の要件を満たさない
- 誤削除からの復旧が不可能
- 監査要件に対応できない

### 案2: paranoia gem の使用

**実装例**:
```ruby
# paranoia gem を使用
class SimpleTransaction < ApplicationRecord
  acts_as_paranoid
end

# 削除（deleted_at が設定される）
@transaction.destroy

# 復元
@transaction.restore

# 本当に削除
@transaction.really_destroy!
```

**メリット**:
- 論理削除の標準的な実装
- 削除日時を自動記録
- 復元機能が標準で提供

**デメリット**:
- 追加の gem が必要
- deleted_at カラムの追加が必要
- キャンセルと削除の区別ができない

**却下理由**:
- キャンセルと削除を区別したい
- ステータスによる管理の方が柔軟
- 追加の gem を避けたい（シンプルさ優先）

### 案3: アーカイブテーブルへの移動

**実装例**:
```ruby
def destroy
  ActiveRecord::Base.transaction do
    # アーカイブテーブルにコピー
    ArchivedSimpleTransaction.create!(@simple_transaction.attributes)

    # 元のテーブルから削除
    @simple_transaction.destroy!
  end
end
```

**メリット**:
- アクティブなテーブルサイズを小さく保てる
- 削除済みデータは別テーブルで管理
- パフォーマンスの向上

**デメリット**:
- テーブル構造が複雑になる
- マイグレーションが複雑
- クエリが複雑（両方のテーブルを検索）

**却下理由**:
- 小規模プロジェクトには過剰設計
- テーブル管理が複雑になる
- 現時点でパフォーマンス問題はない

## 実装詳細

### モデル定義

```ruby
class SimpleTransaction < ApplicationRecord
  # ステータスの定義
  enum status: {
    active: 'active',
    cancelled: 'cancelled',
    deleted: 'deleted'
  }

  # スコープの定義
  scope :active, -> { where(status: 'active') }
  scope :cancelled, -> { where(status: 'cancelled') }
  scope :deleted, -> { where(status: 'deleted') }
  scope :not_deleted, -> { where.not(status: 'deleted') }

  # バリデーション
  validates :status, presence: true, inclusion: { in: %w[active cancelled deleted] }
end
```

**注意**: Rails の enum は使用せず、文字列で管理する方針（可読性とデータベースの互換性のため）。

### コントローラー

```ruby
class Admin::SimpleTransactionsController < ApplicationController
  # 削除（論理削除）
  def destroy
    @simple_transaction = SimpleTransaction.find(params[:id])
    @simple_transaction.update!(status: 'deleted')
    redirect_to admin_simple_transactions_path, notice: '取引を削除しました'
  end

  # キャンセル
  def cancel
    @simple_transaction = SimpleTransaction.find(params[:id])
    @simple_transaction.update!(status: 'cancelled')
    redirect_to admin_simple_transaction_path(@simple_transaction), notice: '取引をキャンセルしました'
  end

  # 一覧表示（デフォルトは active のみ）
  def index
    @simple_transactions = SimpleTransaction.where(status: 'active')
      .order(registration_datetime: :desc)
  end

  # すべてを表示（削除済み含む）
  def index_all
    @simple_transactions = SimpleTransaction.all
      .order(registration_datetime: :desc)
  end
end
```

### ビュー

```erb
<!-- 削除ボタン -->
<%= link_to "削除",
    admin_simple_transaction_path(transaction),
    method: :delete,
    data: { turbo_method: :delete, turbo_confirm: '本当に削除しますか？' },
    style: "color: #dc3545; ..." %>

<!-- キャンセルボタン -->
<%= link_to "キャンセル",
    cancel_admin_simple_transaction_path(transaction),
    method: :patch,
    data: { turbo_method: :patch, turbo_confirm: '本当にキャンセルしますか？' },
    style: "color: #ffc107; ..." %>
```

### マイグレーション

```ruby
class CreateSimpleTransactions < ActiveRecord::Migration[7.2]
  def change
    create_table :simple_transactions do |t|
      t.integer :amount, null: false
      t.datetime :registration_datetime, null: false
      t.string :status, null: false, default: 'active'  # デフォルトは active

      t.timestamps
    end

    add_index :simple_transactions, :status
  end
end
```

## 将来的な拡張

### 削除理由の記録

```ruby
# マイグレーション
add_column :simple_transactions, :deletion_reason, :text

# モデル
class SimpleTransaction < ApplicationRecord
  def soft_delete(reason:)
    update!(
      status: 'deleted',
      deletion_reason: reason
    )
  end
end
```

### 削除者の記録（認証実装後）

```ruby
# マイグレーション
add_column :simple_transactions, :deleted_by, :bigint
add_foreign_key :simple_transactions, :users, column: :deleted_by

# モデル
class SimpleTransaction < ApplicationRecord
  belongs_to :deleted_by_user, class_name: 'User', foreign_key: 'deleted_by', optional: true

  def soft_delete(user:, reason: nil)
    update!(
      status: 'deleted',
      deleted_by: user.id,
      deletion_reason: reason
    )
  end
end
```

### 自動アーカイブ

```ruby
# 定期タスク（rake タスク）
namespace :db do
  desc '1年以上前の削除済み取引をアーカイブ'
  task archive_old_deleted_transactions: :environment do
    one_year_ago = 1.year.ago

    SimpleTransaction.where(status: 'deleted')
      .where('updated_at < ?', one_year_ago)
      .find_each do |transaction|
        # アーカイブ処理（将来的な実装）
        # ArchivedSimpleTransaction.create!(transaction.attributes)
        # transaction.really_destroy!
      end
  end
end
```

## 参考資料

- [Rails Guides: Active Record Callbacks](https://guides.rubyonrails.org/active_record_callbacks.html)
- [Paranoia Gem](https://github.com/rubysherpas/paranoia)
- [データベース設計](../architecture/database.md)

## 関連ADR

- [ADR-001: PostgreSQL の採用](001-database-choice.md) - ステータスインデックスの活用
- [ADR-004: ネストされた属性による一括保存](004-nested-attributes.md) - トランザクション処理との関連
