# データベース設計

## 概要

SMDL簡易版ウェブアプリのデータベーススキーマ定義です。PostgreSQL 16を使用しています。

## ER図

```
┌─────────────────────────┐
│  simple_transactions    │
├─────────────────────────┤
│ id (PK)                 │
│ amount                  │
│ registration_datetime   │
│ status                  │
│ created_at              │
│ updated_at              │
└──────────┬──────────────┘
           │ 1
           │
           │ N
┌──────────▼──────────────────┐
│ simple_transaction_items    │
├─────────────────────────────┤
│ id (PK)                     │
│ simple_transaction_id (FK)  │
│ item_name                   │
│ item_count                  │
│ item_price                  │
│ created_at                  │
│ updated_at                  │
└─────────────────────────────┘

┌─────────────────────────┐
│  simple_transactions    │
└──────────┬──────────────┘
           │ 1
           │
           │ N
┌──────────▼──────────────┐
│  api_call_logs          │
├─────────────────────────┤
│ id (PK)                 │
│ api_type                │
│ endpoint                │
│ request_body            │
│ response_body           │
│ status                  │
│ simple_transaction_id   │
│ called_at               │
│ created_at              │
│ updated_at              │
└─────────────────────────┘
```

## テーブル定義

### simple_transactions（取引テーブル）

**用途**: 取引情報を管理

| カラム名 | 型 | NULL | デフォルト | 説明 |
|---------|-----|------|-----------|------|
| id | bigint | NO | auto | 主キー（自動生成） |
| amount | integer | NO | - | 取引金額（税込） |
| registration_datetime | timestamp | NO | - | 登録日時 |
| status | string | NO | 'active' | ステータス（active/cancelled/deleted） |
| created_at | timestamp | NO | - | レコード作成日時 |
| updated_at | timestamp | NO | - | レコード更新日時 |

**インデックス**:
```sql
CREATE INDEX index_simple_transactions_on_status
  ON simple_transactions(status);

CREATE INDEX index_simple_transactions_on_registration_datetime
  ON simple_transactions(registration_datetime);
```

**制約**:
- `amount` は1以上の整数
- `status` は 'active', 'cancelled', 'deleted' のいずれか
- `registration_datetime` は必須

**ステータスの意味**:
- `active`: 有効な取引
- `cancelled`: キャンセルされた取引
- `deleted`: 削除された取引

### simple_transaction_items（商品テーブル）

**用途**: 取引に紐づく商品情報を管理

| カラム名 | 型 | NULL | デフォルト | 説明 |
|---------|-----|------|-----------|------|
| id | bigint | NO | auto | 主キー（自動生成） |
| simple_transaction_id | bigint | NO | - | 取引ID（外部キー） |
| item_name | string(255) | NO | - | 商品名 |
| item_count | integer | NO | - | 商品個数 |
| item_price | integer | NO | - | 商品単価（税込） |
| created_at | timestamp | NO | - | レコード作成日時 |
| updated_at | timestamp | NO | - | レコード更新日時 |

**インデックス**:
```sql
CREATE INDEX index_simple_transaction_items_on_simple_transaction_id
  ON simple_transaction_items(simple_transaction_id);
```

**外部キー**:
```sql
ALTER TABLE simple_transaction_items
  ADD CONSTRAINT fk_rails_simple_transaction_items_simple_transactions
  FOREIGN KEY (simple_transaction_id)
  REFERENCES simple_transactions(id)
  ON DELETE CASCADE;
```

**制約**:
- `item_name` は最大255文字
- `item_count` は1以上99999以下の整数
- `item_price` は1以上の整数

### api_call_logs（API呼び出し履歴テーブル）

**用途**: API呼び出しの履歴を記録

| カラム名 | 型 | NULL | デフォルト | 説明 |
|---------|-----|------|-----------|------|
| id | bigint | NO | auto | 主キー（自動生成） |
| api_type | string | NO | - | APIタイプ（sapi/smdl） |
| endpoint | string | NO | - | エンドポイント |
| request_body | text | YES | - | リクエストボディ（JSON） |
| response_body | text | YES | - | レスポンスボディ（JSON） |
| status | string | NO | - | ステータス（success/error） |
| simple_transaction_id | bigint | YES | - | 取引ID（外部キー、任意） |
| called_at | timestamp | NO | - | API呼び出し日時 |
| created_at | timestamp | NO | - | レコード作成日時 |
| updated_at | timestamp | NO | - | レコード更新日時 |

**インデックス**:
```sql
CREATE INDEX index_api_call_logs_on_api_type
  ON api_call_logs(api_type);

CREATE INDEX index_api_call_logs_on_called_at
  ON api_call_logs(called_at);

CREATE INDEX index_api_call_logs_on_simple_transaction_id
  ON api_call_logs(simple_transaction_id);
```

**外部キー**:
```sql
ALTER TABLE api_call_logs
  ADD CONSTRAINT fk_rails_api_call_logs_simple_transactions
  FOREIGN KEY (simple_transaction_id)
  REFERENCES simple_transactions(id)
  ON DELETE SET NULL;
```

**制約**:
- `api_type` は 'sapi', 'smdl' のいずれか
- `status` は 'success', 'error' のいずれか
- `simple_transaction_id` はNULL可（取引に紐づかないログも記録可能）

**APIタイプの意味**:
- `sapi`: 簡易版独自API（SMDL Simple API）
- `smdl`: 既存SMDLシステムAPI（将来的な拡張用）

## データ整合性

### リレーションシップ

1. **SimpleTransaction ↔ SimpleTransactionItem**
   - 関係: 1対多
   - 削除: CASCADE（取引削除時に商品も削除）
   - 更新: accepts_nested_attributes_for により一括更新可能

2. **SimpleTransaction ↔ ApiCallLog**
   - 関係: 1対多
   - 削除: SET NULL（取引削除時もログは保持）
   - 更新: 独立して管理

### バリデーション

#### アプリケーションレベル（Rails）

```ruby
# SimpleTransaction
validates :amount, presence: true, numericality: { greater_than: 0 }
validates :status, inclusion: { in: %w[active cancelled deleted] }

# SimpleTransactionItem
validates :item_name, presence: true, length: { maximum: 255 }
validates :item_count, numericality: { greater_than: 0, less_than: 100000 }
validates :item_price, numericality: { greater_than: 0 }

# ApiCallLog
validates :api_type, presence: true
validates :endpoint, presence: true
validates :status, inclusion: { in: %w[success error] }
```

#### データベースレベル

- NOT NULL制約
- 外部キー制約
- インデックスによる検索パフォーマンス最適化

## パフォーマンス最適化

### インデックス戦略

1. **検索頻度の高いカラムにインデックス**
   - `simple_transactions.status` - ステータス検索
   - `simple_transactions.registration_datetime` - 日付範囲検索
   - `api_call_logs.called_at` - 日付範囲検索
   - `api_call_logs.api_type` - APIタイプ絞り込み

2. **外部キーには自動的にインデックス**
   - `simple_transaction_items.simple_transaction_id`
   - `api_call_logs.simple_transaction_id`

### クエリ最適化

```ruby
# N+1クエリを防ぐ
SimpleTransaction.includes(:simple_transaction_items)
ApiCallLog.includes(:simple_transaction)

# 必要なカラムのみ取得
SimpleTransaction.select(:id, :amount, :status)

# ページネーション
SimpleTransaction.limit(100).offset(0)
```

## マイグレーション履歴

### 作成順序

1. `20251225_create_simple_transactions.rb`
   - simple_transactionsテーブル作成

2. `20251225_create_simple_transaction_items.rb`
   - simple_transaction_itemsテーブル作成

3. `20251226_create_api_call_logs.rb`
   - api_call_logsテーブル作成

## サンプルクエリ

### 取引と商品を一括取得
```sql
SELECT st.*, sti.*
FROM simple_transactions st
LEFT JOIN simple_transaction_items sti ON st.id = sti.simple_transaction_id
WHERE st.status = 'active'
ORDER BY st.registration_datetime DESC;
```

### 期間内のAPI呼び出し成功率
```sql
SELECT
  COUNT(*) as total_calls,
  COUNT(CASE WHEN status = 'success' THEN 1 END) as success_count,
  ROUND(COUNT(CASE WHEN status = 'success' THEN 1 END)::numeric / COUNT(*) * 100, 2) as success_rate
FROM api_call_logs
WHERE called_at BETWEEN '2025-12-01' AND '2025-12-31';
```

### 取引金額の集計
```sql
SELECT
  DATE(registration_datetime) as date,
  COUNT(*) as transaction_count,
  SUM(amount) as total_amount,
  AVG(amount) as average_amount
FROM simple_transactions
WHERE status = 'active'
GROUP BY DATE(registration_datetime)
ORDER BY date DESC;
```

## データ保持ポリシー

### 現在の方針
- 取引データ: 無期限保持
- API履歴: 無期限保持（将来的にはアーカイブ化を検討）

### 将来的な改善案
- [ ] 古いAPI履歴の自動アーカイブ（90日以上）
- [ ] 削除済み取引の定期的なハードデリート（1年以上）
- [ ] パフォーマンス監視と定期的なVACUUM実行

## バックアップとリストア

### 推奨バックアップ戦略

```bash
# 全データベースバックアップ
pg_dump -U postgres -d smdl_simple_app_production > backup.sql

# 特定テーブルのみバックアップ
pg_dump -U postgres -d smdl_simple_app_production -t simple_transactions > transactions_backup.sql

# リストア
psql -U postgres -d smdl_simple_app_production < backup.sql
```

## 関連ドキュメント

- [システムアーキテクチャ](system.md)
- [処理フロー](../flows/transaction-flow.md)
- [ADR: データベース選定](../adr/001-database-choice.md)
