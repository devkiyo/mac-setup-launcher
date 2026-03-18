# mac-setup-launcher

Private リポジトリに置いた `mac-setup` の起動入口です。

## 使い方

```bash
curl -fsSL https://raw.githubusercontent.com/devkiyo/mac-setup-launcher/main/bootstrap-remote.sh | bash
```

実行中に GitHub PAT の入力を求められます。

## 必要なPAT権限

Fine-grained PAT を推奨します。

- Resource owner: `devkiyo`
- Repository access: `Only select repositories` で `mac-setup`
- Permissions: `Contents` を `Read-only`

## PAT発行手順（Fine-grained PAT）

1. GitHub にログイン
2. 右上アイコンから `Settings` を開く
3. 左メニューで `Developer settings` を開く
4. `Personal access tokens` → `Fine-grained tokens` を開く
5. `Generate new token` を選択
6. Token name を入力（例: `mac-setup-launcher`）
7. Expiration を設定（短め推奨）
8. `Resource owner` で `devkiyo` を選択
9. `Repository access` は `Only select repositories` を選び、`mac-setup` のみ指定
10. `Permissions` の `Repository permissions` で `Contents: Read-only` を設定
11. `Generate token` を押す
12. 表示されたトークンをコピー（この画面でしか再表示不可）

## 実行時の入力例

```bash
GitHub PAT (repo read-only) を入力してください:
```

入力は非表示です。

## 補足

- `GITHUB_PAT` 環境変数がある場合は対話入力を省略できます。
- clone 先は `~/.mac-setup` です。
- `~/.mac-setup` が Git 管理外ディレクトリだった場合は
  `~/.mac-setup.backup.YYYYMMDD-HHMMSS` に退避してから clone します。
