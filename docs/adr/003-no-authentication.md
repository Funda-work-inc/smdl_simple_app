# ADR-003: 認証機能の非実装

## ステータス

**承認済み** (2025-12-25)

## コンテキスト

SMDL簡易版ウェブアプリの初期バージョンにおいて、認証・認可機能を実装するかどうかを検討する必要があった。

### 要件

- ユーザー画面と管理者画面を提供する
- 開発・学習用プロジェクトとして、段階的に機能を追加したい
- 初期バージョンではコア機能（取引登録・管理）に集中したい

### 検討時の制約

- 開発リソースが限られている
- 早期にMVP（Minimum Viable Product）をリリースしたい
- 段階的な機能追加が可能な設計にしたい

## 決定

初期バージョン（v1.0）では、**認証・認可機能を実装しない**。

### 決定内容

1. **ユーザー画面**: 誰でもアクセス可能
2. **管理者画面**: 誰でもアクセス可能
3. **API**: 誰でも呼び出し可能（CSRF保護はスキップ）

### 将来的な実装予定

- v2.0 で認証機能を追加予定
- Devise または Sorcery を使用予定
- CanCanCan または Pundit で認可機能を実装予定

## 結果

### ポジティブな影響

- **開発速度の向上**
  - コア機能の実装に集中できる
  - 初期バージョンを早期にリリースできる

- **学習のシンプル化**
  - 認証・認可のロジックを考慮せずに、コア機能を学習できる
  - テストがシンプルになる

- **段階的な機能追加**
  - まずコア機能を完成させ、その後に認証を追加する
  - 段階的な学習が可能

- **デバッグの容易さ**
  - 認証エラーを考慮しなくて良い
  - 開発中のテストが容易

### ネガティブな影響

- **セキュリティリスク**
  - 本番環境での利用には不適切
  - 誰でも管理者画面にアクセス可能
  - APIが外部から呼び出し可能

- **機能制限**
  - ユーザーごとのデータ管理ができない
  - 操作ログにユーザー情報を記録できない

- **将来的なリファクタリング**
  - 認証追加時に既存コードの修正が必要
  - マイグレーションの追加が必要

### 中立的な影響

- **ローカル開発専用**
  - 本アプリケーションはローカル環境での開発・学習用途に限定
  - 外部公開しない前提での設計

## 代替案

### 案1: Basic認証の実装

**メリット**:
- 実装が非常に簡単
- Railsの標準機能で実装可能
- 最低限のアクセス制御が可能

**デメリット**:
- ユーザー管理機能がない
- セッション管理が不十分
- 本格的な認証には不向き

**却下理由**:
- 中途半端な実装になる
- 将来的に Devise などに置き換える必要がある
- 段階的な実装が難しい

### 案2: Deviseの即時実装

**メリット**:
- 本格的な認証機能
- Rails のデファクトスタンダード
- 豊富な機能とドキュメント

**デメリット**:
- 初期の学習コストが高い
- コア機能の実装が遅れる
- 設定やカスタマイズが複雑

**却下理由**:
- 初期バージョンではコア機能に集中したい
- MVPのリリースを優先
- 段階的な学習を重視

### 案3: 独自の認証機能実装

**メリット**:
- 柔軟にカスタマイズ可能
- 学習効果が高い
- 必要最小限の機能に絞れる

**デメリット**:
- セキュリティリスクが高い
- 開発コストが高い
- メンテナンスコストが高い

**却下理由**:
- セキュリティ専門家でない限り、独自実装は避けるべき
- 既存のライブラリを使う方が安全
- コストに見合うメリットがない

## 実装詳細

### 現在のアクセス制御

```ruby
# すべてのコントローラーで認証をスキップ
class ApplicationController < ActionController::Base
  # before_action :authenticate_user! # 未実装
end

# API では CSRF 保護もスキップ
class API::V1::SimpleTransactionsController < ApplicationController
  skip_before_action :verify_authenticity_token
end
```

### 将来的な実装イメージ（v2.0）

```ruby
# Devise を使用した認証
class ApplicationController < ActionController::Base
  before_action :authenticate_user!
end

# 管理者画面は admin ロールが必要
class Admin::SimpleTransactionsController < ApplicationController
  before_action :require_admin

  private

  def require_admin
    redirect_to root_path unless current_user&.admin?
  end
end

# API は API トークン認証
class API::V1::SimpleTransactionsController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :authenticate_api_token

  private

  def authenticate_api_token
    # API トークンによる認証
  end
end
```

### マイグレーション予定

```ruby
# v2.0 で追加予定
class DeviseCreateUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :users do |t|
      # Devise の標準カラム
      t.string :email, null: false, default: ""
      t.string :encrypted_password, null: false, default: ""
      t.string :role, default: "user" # user / admin

      # その他の Devise カラム
      # ...

      t.timestamps
    end

    add_index :users, :email, unique: true
  end
end
```

## リスク管理

### 現在のリスクと軽減策

1. **セキュリティリスク**
   - **リスク**: 誰でもアクセス可能
   - **軽減策**: ローカル環境のみで使用、外部公開しない

2. **データ漏洩リスク**
   - **リスク**: 機密情報が含まれる可能性
   - **軽減策**: テストデータのみ使用、本番環境で使用しない

3. **不正操作リスク**
   - **リスク**: 誰でも削除・更新可能
   - **軽減策**: 定期的なバックアップ、論理削除の採用

### v2.0 での対応予定

- [ ] Devise による認証機能の実装
- [ ] CanCanCan または Pundit による認可機能
- [ ] API トークン認証の実装
- [ ] 監査ログの強化（ユーザー情報の記録）

## 参考資料

- [Devise GitHub](https://github.com/heartcombo/devise)
- [Sorcery GitHub](https://github.com/Sorcery/sorcery)
- [Rails Security Guide](https://guides.rubyonrails.org/security.html)

## 関連ADR

- なし
