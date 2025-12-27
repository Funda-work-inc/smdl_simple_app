# 取引処理フロー

## 概要

SMDL簡易版における取引登録から管理までの処理フローを説明します。

## 1. 取引登録フロー（ユーザー画面）

### フロー図

```
┌─────────────────────┐
│ ユーザー            │
└──────┬──────────────┘
       │ 1. アクセス
       ▼
┌─────────────────────────────────┐
│ GET /simple_transactions/new    │
│ 取引登録画面表示                 │
└──────┬──────────────────────────┘
       │ 2. 入力
       │   - 取引金額
       │   - 商品情報（複数）
       ▼
┌─────────────────────────────────┐
│ POST /simple_transactions       │
│ SimpleTransactionsController    │
│ #create                         │
└──────┬──────────────────────────┘
       │ 3. バリデーション
       ▼
┌─────────────────────────────────┐
│ SimpleTransaction.new           │
│ + nested attributes             │
└──────┬──────────────────────────┘
       │
       ├─ NG ────────────────────┐
       │                         │
       │ 4. OK                   ▼
       │                  ┌─────────────────┐
       │                  │ render :new     │
       ▼                  │ エラー表示       │
┌─────────────────────┐  └─────────────────┘
│ transaction.save!   │
│ DB保存              │
└──────┬──────────────┘
       │ 5. 成功
       ▼
┌─────────────────────────────────┐
│ redirect_to                     │
│ simple_transaction_path(id)     │
└──────┬──────────────────────────┘
       │ 6. 表示
       ▼
┌─────────────────────────────────┐
│ GET /simple_transactions/:id    │
│ 取引結果表示画面                 │
└─────────────────────────────────┘
```

### 処理詳細

#### ステップ1: 画面表示
```ruby
# SimpleTransactionsController#new
def new
  # 新規登録画面を表示
end
```

#### ステップ2-3: 入力とバリデーション
```ruby
# SimpleTransactionsController#create
def create
  @simple_transaction = SimpleTransaction.new(transaction_params)

  # ネストされた商品情報も一緒にバリデーション
  @simple_transaction.simple_transaction_items.build(items_params)

  if @simple_transaction.valid?
    # バリデーションOK
  else
    # バリデーションNG - エラーメッセージ表示
    render :new, status: :unprocessable_entity
  end
end
```

#### ステップ4: データベース保存
```ruby
# トランザクション内で保存
ActiveRecord::Base.transaction do
  @simple_transaction.save!
  # 商品情報も一緒に保存される（nested attributes）
end
```

#### ステップ5-6: 結果表示
```ruby
# 成功時は結果画面にリダイレクト
redirect_to simple_transaction_path(@simple_transaction)
```

## 2. API取引登録フロー

### フロー図

```
┌─────────────────────┐
│ 外部システム         │
└──────┬──────────────┘
       │ 1. API呼び出し
       │ POST /api/v1/simple_transactions
       │ Content-Type: application/json
       ▼
┌──────────────────────────────────────┐
│ API::V1::SimpleTransactionsController│
│ #create                              │
└──────┬───────────────────────────────┘
       │ 2. パラメーター解析
       ▼
┌─────────────────────────────────┐
│ transaction_params              │
│ - amount                        │
│ - items: [...]                  │
└──────┬──────────────────────────┘
       │ 3. モデル作成
       ▼
┌─────────────────────────────────┐
│ SimpleTransaction.new           │
│ + SimpleTransactionItem (N件)   │
└──────┬──────────────────────────┘
       │ 4. バリデーション
       ├─ NG ──────────────────┐
       │                       │
       │ 5. OK                 ▼
       ▼                ┌────────────────────┐
┌─────────────────┐    │ ApiCallLog.create! │
│ transaction.save│    │ status: 'error'    │
└──────┬──────────┘    └──────┬─────────────┘
       │ 6. 成功              │
       ▼                      ▼
┌─────────────────┐    ┌────────────────────┐
│ ApiCallLog.     │    │ render json:       │
│ create!         │    │ { errors: [...] }  │
│ status:'success'│    │ status: 422        │
└──────┬──────────┘    └────────────────────┘
       │ 7. レスポンス
       ▼
┌─────────────────────────────────┐
│ render json:                    │
│ {                               │
│   id: 123,                      │
│   amount: 10000,                │
│   status: 'active',             │
│   message: 'Transaction created'│
│ }                               │
│ status: 201                     │
└─────────────────────────────────┘
```

### 処理詳細

#### APIログ記録
```ruby
# 成功時
ApiCallLog.create!(
  api_type: 'sapi',
  endpoint: 'POST /api/v1/simple_transactions',
  request_body: request.body.read,
  response_body: response.body,
  status: 'success',
  simple_transaction_id: @simple_transaction.id,
  called_at: Time.current
)

# エラー時
ApiCallLog.create!(
  api_type: 'sapi',
  endpoint: 'POST /api/v1/simple_transactions',
  request_body: request.body.read,
  response_body: { errors: errors }.to_json,
  status: 'error',
  simple_transaction_id: nil,
  called_at: Time.current
)
```

## 3. 管理者画面フロー

### 3.1 取引一覧・検索フロー

```
┌─────────────────────┐
│ 管理者              │
└──────┬──────────────┘
       │ 1. アクセス
       ▼
┌─────────────────────────────────┐
│ GET /admin/simple_transactions  │
│ 一覧画面表示                     │
└──────┬──────────────────────────┘
       │ 2. 検索フィルター適用（任意）
       │   - id: 取引ID
       │   - date_from: 開始日
       │   - date_to: 終了日
       ▼
┌─────────────────────────────────┐
│ Admin::SimpleTransactionsController│
│ #index                          │
│                                 │
│ @transactions = SimpleTransaction│
│   .includes(:simple_transaction_items)│
│   .where(id: params[:id])       │  # 任意
│   .where('registration_datetime >= ?', date_from)│ # 任意
│   .where('registration_datetime <= ?', date_to)│   # 任意
│   .order(registration_datetime: :desc)│
└──────┬──────────────────────────┘
       │ 3. 結果表示
       ▼
┌─────────────────────────────────┐
│ admin/simple_transactions/      │
│ index.html.erb                  │
│                                 │
│ - 取引一覧テーブル               │
│ - 詳細・更新・削除ボタン         │
└─────────────────────────────────┘
```

### 3.2 取引更新フロー

```
┌─────────────────────┐
│ 管理者              │
└──────┬──────────────┘
       │ 1. 更新ボタンクリック
       ▼
┌─────────────────────────────────┐
│ GET /admin/simple_transactions/:id/edit│
│ 更新画面表示                     │
└──────┬──────────────────────────┘
       │ 2. 編集
       │   - 取引金額変更
       │   - 商品追加・削除・編集
       ▼
┌─────────────────────────────────┐
│ PATCH /admin/simple_transactions/:id│
│ Admin::SimpleTransactionsController#update│
└──────┬──────────────────────────┘
       │ 3. バリデーション
       ├─ NG ──────────────────┐
       │                       │
       │ 4. OK                 ▼
       ▼                ┌────────────────┐
┌─────────────────┐    │ render :edit   │
│ transaction.    │    │ エラー表示      │
│ update!         │    └────────────────┘
└──────┬──────────┘
       │ 5. 成功
       ▼
┌─────────────────────────────────┐
│ redirect_to                     │
│ admin_simple_transaction_path(id)│
│ notice: '取引を更新しました'      │
└─────────────────────────────────┘
```

### 3.3 取引削除・キャンセルフロー

```
┌─────────────────────┐
│ 管理者              │
└──────┬──────────────┘
       │ 1. 削除/キャンセルボタンクリック
       │ （確認ダイアログ表示）
       ▼
┌─────────────────────────────────┐
│ DELETE /admin/simple_transactions/:id│
│ または                           │
│ PATCH /admin/simple_transactions/:id/cancel│
└──────┬──────────────────────────┘
       │ 2. ステータス更新
       ▼
┌─────────────────────────────────┐
│ transaction.update!(            │
│   status: 'deleted'             │  # 削除の場合
│   # または 'cancelled'           │  # キャンセルの場合
│ )                               │
└──────┬──────────────────────────┘
       │ 3. リダイレクト
       ▼
┌─────────────────────────────────┐
│ DELETE: 一覧画面へリダイレクト   │
│ CANCEL: 詳細画面へリダイレクト   │
└─────────────────────────────────┘
```

**重要**: 削除・キャンセルは物理削除ではなく、ステータス更新による論理削除です。

## 4. API履歴確認フロー

```
┌─────────────────────┐
│ 管理者              │
└──────┬──────────────┘
       │ 1. アクセス
       ▼
┌─────────────────────────────────┐
│ GET /admin/api_call_logs        │
│ API履歴一覧画面                  │
└──────┬──────────────────────────┘
       │ 2. フィルター適用（任意）
       │   - date_from: 開始日
       │   - endpoint: エンドポイント
       │   - api_type: APIタイプ
       │   - status: ステータス
       ▼
┌─────────────────────────────────┐
│ Admin::ApiCallLogsController    │
│ #index                          │
│                                 │
│ @logs = ApiCallLog              │
│   .includes(:simple_transaction)│
│   .where('called_at >= ?', date_from)│ # 任意
│   .where('endpoint LIKE ?', "%#{endpoint}%")│ # 任意
│   .where(api_type: api_type)    │  # 任意
│   .where(status: status)        │  # 任意
│   .order(called_at: :desc)      │
│   .limit(100)                   │
└──────┬──────────────────────────┘
       │ 3. 結果表示
       ▼
┌─────────────────────────────────┐
│ admin/api_call_logs/            │
│ index.html.erb                  │
│                                 │
│ - API履歴テーブル                │
│ - 詳細ボタン                     │
└─────────────────────────────────┘
```

## 5. エラーハンドリング

### バリデーションエラー

```ruby
# モデルレベルのバリデーション
class SimpleTransaction < ApplicationRecord
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :registration_datetime, presence: true
  validates :status, inclusion: { in: %w[active cancelled deleted] }
end

# エラーメッセージの取得
if @transaction.invalid?
  @transaction.errors.full_messages
  # => ["Amount must be greater than 0", "Status is not included in the list"]
end
```

### データベースエラー

```ruby
begin
  ActiveRecord::Base.transaction do
    @transaction.save!
  end
rescue ActiveRecord::RecordInvalid => e
  # バリデーションエラー
  render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
rescue ActiveRecord::RecordNotFound => e
  # レコードが見つからない
  render json: { error: 'Transaction not found' }, status: :not_found
rescue => e
  # その他のエラー
  render json: { error: 'Internal server error' }, status: :internal_server_error
end
```

## 6. パフォーマンス最適化

### N+1クエリ対策

```ruby
# 悪い例（N+1クエリ発生）
@transactions = SimpleTransaction.all
@transactions.each do |transaction|
  transaction.simple_transaction_items.each do |item|
    # ...
  end
end

# 良い例（一括読み込み）
@transactions = SimpleTransaction.includes(:simple_transaction_items).all
@transactions.each do |transaction|
  transaction.simple_transaction_items.each do |item|
    # ...
  end
end
```

### ページネーション

```ruby
# 大量のデータを扱う場合
@transactions = SimpleTransaction
  .includes(:simple_transaction_items)
  .limit(100)
  .offset(params[:page].to_i * 100)
```

## 7. セキュリティ考慮事項

### Strong Parameters

```ruby
def transaction_params
  params.require(:simple_transaction).permit(
    :amount,
    simple_transaction_items_attributes: [
      :id, :item_name, :item_count, :item_price, :_destroy
    ]
  )
end
```

### CSRF保護

```ruby
# Web画面では標準のCSRF保護
class SimpleTransactionsController < ApplicationController
  # protect_from_forgery with: :exception (デフォルト)
end

# API では CSRF 保護をスキップ
class API::V1::SimpleTransactionsController < ApplicationController
  skip_before_action :verify_authenticity_token
end
```

## 関連ドキュメント

- [システムアーキテクチャ](../architecture/system.md)
- [データベース設計](../architecture/database.md)
- [ADR一覧](../adr/)
