# SMDL簡易版ウェブアプリ

SMDL（決済モジュール）の簡易版ウェブアプリケーション。基本的な取引登録機能と管理機能を提供します。

## 📋 プロジェクト概要

既存のSMDLシステムを簡略化し、最小限の入力項目（金額・個数・商品名）で取引登録が可能なWebアプリケーションです。ユーザー画面と管理者画面を分離した構成で、ショッピングサイトの加盟店管理画面のような使い勝手を実現しています。

### 主な特徴

- 画面ベースでの取引登録（最小限の入力項目）
- ユーザー画面と管理者画面の分離
- データベースへの直接保存
- API経由での取引操作
- API呼び出し履歴の記録・管理
- TDD（テスト駆動開発）による実装

## 🚀 技術スタック

| レイヤー | 技術 | バージョン |
|---------|------|-----------|
| フレームワーク | Ruby on Rails | 7.2.3 |
| 言語 | Ruby | 3.3.0 |
| データベース | PostgreSQL | 16 |
| テスト | RSpec | 7.1 |
| Webサーバー | Puma | - |

## 📦 セットアップ

### 必要な環境

- Ruby 3.3.0
- PostgreSQL 16
- Bundler

### インストール手順

1. リポジトリのクローン
```bash
git clone https://github.com/Funda-work-inc/smdl_simple_app.git
cd smdl_simple_app
```

2. 依存関係のインストール
```bash
bundle install
```

3. データベースのセットアップ
```bash
rails db:create
rails db:migrate
```

4. サーバーの起動
```bash
rails server
```

5. ブラウザでアクセス
- ユーザー画面: http://localhost:3000/simple_transactions/new
- 管理者画面: http://localhost:3000/admin/simple_transactions

## 🎯 主な機能

### ユーザー画面

- **取引登録画面** (`/simple_transactions/new`)
  - 取引金額の入力
  - 複数商品の登録（商品名・個数・単価）
  - 商品行の追加・削除
  - バリデーション機能

- **取引結果表示画面** (`/simple_transactions/:id`)
  - 登録した取引の詳細表示
  - 取引ID、登録日時、金額、商品情報の確認

### 管理者画面

- **取引一覧画面** (`/admin/simple_transactions`)
  - 登録された取引の一覧表示
  - 取引ID、登録日時、金額での検索機能
  - 取引の更新・削除・キャンセル操作

- **取引詳細画面** (`/admin/simple_transactions/:id`)
  - 取引情報の詳細表示
  - 商品情報の表示
  - API呼び出し履歴の確認

- **取引更新画面** (`/admin/simple_transactions/:id/edit`)
  - 既存取引の金額・商品情報の更新
  - 商品の追加・削除

- **API呼び出し履歴画面** (`/admin/api_call_logs`)
  - API呼び出しの履歴一覧
  - 日付・エンドポイント・ステータスでの検索

### API機能

- **POST** `/api/v1/simple_transactions` - 取引登録
- **PUT** `/api/v1/simple_transactions/:id` - 取引更新

すべてのAPI呼び出しは自動的にログに記録されます。

## 🧪 テスト

### テストの実行

```bash
# 全テストの実行
bundle exec rspec

# 特定のテストファイルの実行
bundle exec rspec spec/requests/admin/simple_transactions_spec.rb

# 特定のテストケースの実行
bundle exec rspec spec/requests/admin/simple_transactions_spec.rb:14
```

### テストカバレッジ

- リクエストスペック: 66 examples
- モデルスペック: 完全カバレッジ
- TDD（テスト駆動開発）による実装

## 📊 データベース構造

### テーブル一覧

- **simple_transactions** - 取引情報
- **simple_transaction_items** - 商品情報
- **api_call_logs** - API呼び出し履歴

詳細は [データベース設計](docs/architecture/database.md) を参照してください。

## 📚 ドキュメント

- [システムアーキテクチャ](docs/architecture/system.md)
- [データベース設計](docs/architecture/database.md)
- [処理フロー](docs/flows/transaction-flow.md)
- [ADR（意思決定記録）](docs/adr/)

## 🔧 開発

### ブランチ戦略

- `main` - 本番環境用
- `feature/*` - 機能開発用

### コミット規約

```
[種別] 機能名 #Issue番号

例:
[新機能] 管理者画面CRUD完成・プロジェクト最適化 #13
[テスト完成] 取引登録・更新API テスト実装完了 #15
```

### PR作成フロー

1. Issue作成
2. featureブランチ作成
3. テスト作成（TDD: Red）
4. 実装（TDD: Green）
5. リファクタリング
6. コミット＆PR作成
7. レビュー・マージ

## 📝 ライセンス

このプロジェクトは内部利用を目的としています。

## 🤝 コントリビューション

1. Issueを作成
2. featureブランチを作成
3. 変更をコミット
4. PRを作成
5. レビュー後にマージ

## 📞 サポート

質問や問題がある場合は、GitHubのIssuesセクションで報告してください。
