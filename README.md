# self cert generator

自己認証局証明書付きのサーバー証明書を簡単に作成する。
出力先を前回と同じままにすると同じ認証局で証明書を発行するので、
認証局の証明書を端末にインストールするだけで複数の自己証明書を認識できるようになる。


## Build

```
docker build -t selfcert .
```


## 証明書設定

env ファイルを作成し、以下のように任意の内容を入力する。値はデフォルト値
CA設定は同一ディレクトリを指定する間は変更しないことを推奨。
変更した場合の動作は保証しない。

```
# CA 用設定
SUBJ_CA_C=UN
SUBJ_CA_ST=state
SUBJ_CA_L=city
SUBJ_CA_O=selfcert
SUBJ_CA_OU=container
SUBJ_CA_CN=selfcert
SUBJ_CA_emailAddress=selfcert@example.com

# サーバー証明書発行時
SERVER_NAME=localhost

# クライアント証明書時
CLIENT_NAME=your_name
# pfx のパスフレーズ
PASSPHRASE=passphrase

# 証明書用共通設定
# SERVER_NAME 設定時は、サーバー証明書が発行される 両方設定がある場合はこちらが優先される
# CLIENT_NAME 設定時は、クライアント証明書が発行される
SUBJ_C=UN
SUBJ_ST=state
SUBJ_L=city
# 以降はオプション デフォルト値は SERVER_NAME か CLIENT_NAME ベース
#SUBJ_O=SERVER_NAME org
#SUBJ_OU=SERVER_NAME unit
#SUBJ_CN=SERVER_NAME
#SUBJ_emailAddress=selfcert@SERVER_NAME

```


## Run

ホスト側の保存ディレクトリ（下記サンプルではselfcertCA_pki）は、認証局名ごとに分けること

```
docker run --rm -v $PWD/selfcertCA_pki:/pki --env-file env selfcert
```
