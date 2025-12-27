# システムアーキテクチャ

## 概要

SMDL簡易版ウェブアプリは、Rails 7.2のMVCアーキテクチャに基づいた、シンプルで拡張性の高いWebアプリケーションです。

## アーキテクチャ図

```
┌─────────────────────────────────────────┐
│         ユーザー（ブラウザ）             │
└────────────────┬────────────────────────┘
                 │ HTTP/HTTPS
┌────────────────▼────────────────────────┐
│   SMDL簡易版ウェブアプリケーション        │
│  ┌──────────────────────────────────┐   │
│  │  ビュー層（Views）                │   │
│  │  - simple_transactions/          │   │
│  │  - admin/simple_transactions/    │   │
│  │  - admin/api_call_logs/          │   │
│  │  - shared/_header.html.erb       │   │
│  └──────────────────────────────────┘   │
│  ┌──────────────────────────────────┐   │
│  │  コントローラー層（Controllers）   │   │
│  │  - SimpleTransactionsController  │   │
│  │  - Admin::SimpleTransactions     │   │
│  │  - Admin::ApiCallLogsController  │   │
│  │  - API::V1::SimpleTransactions   │   │
│  └──────────────────────────────────┘   │
│  ┌──────────────────────────────────┐   │
│  │  モデル層（Models）               │   │
│  │  - SimpleTransaction             │   │
│  │  - SimpleTransactionItem         │   │
│  │  - ApiCallLog                    │   │
│  └──────────────────────────────────┘   │
└────────────────┬────────────────────────┘
                 │
┌────────────────▼────────────────────────┐
│  データベース（PostgreSQL 16）           │
│  - simple_transactions                  │
│  - simple_transaction_items             │
│  - api_call_logs                        │
└─────────────────────────────────────────┘
```

## レイヤー構成

### 1. ビュー層（Views）

**役割**: ユーザーインターフェースの表示

**主要コンポーネント**:
- **ユーザー画面**
  - `simple_transactions/new.html.erb` - 取引登録画面
  - `simple_transactions/show.html.erb` - 取引結果表示画面

- **管理者画面**
  - `admin/simple_transactions/index.html.erb` - 取引一覧
  - `admin/simple_transactions/show.html.erb` - 取引詳細
  - `admin/simple_transactions/edit.html.erb` - 取引更新
  - `admin/api_call_logs/index.html.erb` - API履歴一覧
  - `admin/api_call_logs/show.html.erb` - API履歴詳細

- **共通コンポーネント**
  - `shared/_header.html.erb` - 固定ヘッダー（全ページ共通）

**特徴**:
- インラインスタイルによるシンプルなデザイン
- レスポンシブ対応
- Turbo対応（Rails 7標準）

### 2. コントローラー層（Controllers）

**役割**: リクエストの処理とビジネスロジックの呼び出し

**主要コンポーネント**:

#### SimpleTransactionsController
```ruby
# ユーザー画面用コントローラー
class SimpleTransactionsController < ApplicationController
  # GET /simple_transactions/new - 新規登録画面
  # POST /simple_transactions - 取引登録処理
  # GET /simple_transactions/:id - 結果表示
end
```

#### Admin::SimpleTransactionsController
```ruby
# 管理者画面用コントローラー
class Admin::SimpleTransactionsController < ApplicationController
  # GET /admin/simple_transactions - 一覧表示
  # GET /admin/simple_transactions/:id - 詳細表示
  # GET /admin/simple_transactions/:id/edit - 更新画面
  # PATCH /admin/simple_transactions/:id - 更新処理
  # DELETE /admin/simple_transactions/:id - 削除処理
  # PATCH /admin/simple_transactions/:id/cancel - キャンセル処理
end
```

#### Admin::ApiCallLogsController
```ruby
# API履歴管理用コントローラー
class Admin::ApiCallLogsController < ApplicationController
  # GET /admin/api_call_logs - 履歴一覧
  # GET /admin/api_call_logs/:id - 履歴詳細
end
```

#### API::V1::SimpleTransactionsController
```ruby
# API用コントローラー
class API::V1::SimpleTransactionsController < ApplicationController
  skip_before_action :verify_authenticity_token

  # POST /api/v1/simple_transactions - 取引登録API
  # PUT /api/v1/simple_transactions/:id - 取引更新API
end
```

### 3. モデル層（Models）

**役割**: ビジネスロジックとデータ永続化

**主要コンポーネント**:

#### SimpleTransaction
```ruby
# 取引モデル
class SimpleTransaction < ApplicationRecord
  has_many :simple_transaction_items, dependent: :destroy
  has_many :api_call_logs, dependent: :destroy

  accepts_nested_attributes_for :simple_transaction_items, allow_destroy: true

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :registration_datetime, presence: true
  validates :status, presence: true, inclusion: { in: %w[active cancelled deleted] }

  scope :active, -> { where(status: 'active') }
  scope :recent, -> { order(created_at: :desc) }
end
```

#### SimpleTransactionItem
```ruby
# 商品モデル
class SimpleTransactionItem < ApplicationRecord
  belongs_to :simple_transaction

  validates :item_name, presence: true, length: { maximum: 255 }
  validates :item_count, presence: true, numericality: { greater_than: 0, less_than: 100000 }
  validates :item_price, presence: true, numericality: { greater_than: 0 }
end
```

#### ApiCallLog
```ruby
# API呼び出し履歴モデル
class ApiCallLog < ApplicationRecord
  belongs_to :simple_transaction, optional: true

  validates :api_type, presence: true
  validates :endpoint, presence: true
  validates :status, presence: true, inclusion: { in: %w[success error] }

  scope :recent, -> { order(called_at: :desc) }
  scope :success, -> { where(status: 'success') }
  scope :error, -> { where(status: 'error') }
end
```

### 4. データベース層

**データベース**: PostgreSQL 16

**主要テーブル**:
- `simple_transactions` - 取引情報
- `simple_transaction_items` - 商品情報
- `api_call_logs` - API呼び出し履歴

詳細は [データベース設計](database.md) を参照してください。

## ルーティング構成

```ruby
Rails.application.routes.draw do
  # ユーザー画面
  resources :simple_transactions, only: [:new, :create, :show]

  # 管理者画面
  namespace :admin do
    resources :simple_transactions, except: [:new] do
      member do
        patch :cancel
      end
    end
    resources :api_call_logs, only: [:index, :show]
  end

  # API
  namespace :api do
    namespace :v1 do
      resources :simple_transactions, only: [:create, :update]
    end
  end
end
```

## セキュリティ

### CSRF保護
- 通常のWebリクエストには標準のCSRF保護を適用
- API エンドポイント (`/api/v1/*`) では `skip_before_action :verify_authenticity_token` を使用

### バリデーション
- すべての入力データはサーバーサイドでバリデーション
- Strong Parameters による パラメーター制限

### データベース
- 外部キー制約によるデータ整合性の保証
- インデックスによるパフォーマンス最適化

## パフォーマンス考慮事項

### N+1クエリ対策
```ruby
# includes を使用した関連データの一括読み込み
@simple_transactions = SimpleTransaction.includes(:simple_transaction_items)
@api_call_logs = ApiCallLog.includes(:simple_transaction)
```

### インデックス
- `simple_transactions.status`
- `simple_transactions.registration_datetime`
- `api_call_logs.called_at`
- `api_call_logs.api_type`

## スケーラビリティ

現在の構成は小〜中規模のトラフィックを想定していますが、以下の拡張が可能です：

1. **キャッシング**: Redis導入によるセッション管理とクエリキャッシュ
2. **非同期処理**: Sidekiq導入によるバックグラウンドジョブ処理
3. **CDN**: 静的アセットの配信最適化
4. **データベース**: レプリケーション・シャーディング

## 技術的負債と改善点

### 現在の制限事項
- 認証・認可機能なし（将来的に追加予定）
- ファイルアップロード機能なし
- リアルタイム通知機能なし

### 将来的な改善
- [ ] Devise/Sorcery による認証機能の追加
- [ ] CanCanCan/Pundit による認可機能の追加
- [ ] Action Cable によるリアルタイム通知
- [ ] Active Storage によるファイルアップロード機能

## 関連ドキュメント

- [データベース設計](database.md)
- [処理フロー](../flows/transaction-flow.md)
- [ADR一覧](../adr/)
