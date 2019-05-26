# AWS-EC2インスタンス上にWordPressを構築する
MacまたはLinuxによる操作を前提としています.<br>
Windowsの場合は, SSH接続などで異なる操作が必要となります.<br>
ソース内部の[]は自分の値に置き換えて実行してください.
## 1. AWSでEC2インスンタンスを立てる
1. Amazon Web Serviceの[アカウント作成](https://aws.amazon.com/jp/)(クレカ情報が必要です)

2. ログインし, **サービス** → **コンピューティング** → **EC2**に入る

3. **インスタンス**タブの, **インスタンスの作成**を選択

4. 手順1:Amazon マシンイメージ(AMI)において**Amazon Linux 2 AMI**を選択<br>
Amazon Linux と Amazon Linux2では違う部分が多々あるので気をつけてください.<br>
`無料利用枠の対象`と表示があるものです.

5. 手順2, 3, 4はデフォルトの選択肢のまま**次の手順**を選択

6. 手順5:タグの追加 はサーバー名をきめるフェーズです.<br>
**タグの追加**から キーを`NAME`, 値を任意のサーバー名にします.<br>
ここでは キー:`NAME`, 値:`test`とします.

7. 手順6:セキュリティグループの設定 では**インバウンド**を設定します. <br>
インバウンドは**サーバにアクセスできるポート**を表します.<br>
通常のWebサイト公開の場合, ソースは<br>
**SSH** : `マイIP`<br>
**HTTP** : `任意の場所`<br>
**HTTPS** : `任意の場所`<br>
になるかと思います.

8. **確認と作成** → **起動** を選択します.
ここで**キーペア**についてのウィンドウが現れます.<br>
このキーペアは, SSH接続の際に用いる秘密鍵で`*.pem`というファイル名です.<br>
以前にインスタンスを作成したことがない場合は, 新しい名前を入力して新しい秘密鍵を作成します.ここでは **キーペア名** : `key` とします.<br>
キーペアをダウンロードし, インスタンスを作成します.

## 2. WordPress環境構築
1. 現状インスタンスの起動ごとにIPアドレスが変わってしまうのでこれを変更します.<br>
**EC2** → **Elastic IP **から **新しいアドレスの割当**を選択し, 割当てます.<br>
割り当てたアドレスを選択し, **アクション**から**アドレスの関連付け**を選択.<br>
先程作成したインスタンスに関連付けます.

2. 作成したインスタンスにSSH接続します.<br>
ダウンロードしたキーペアのパーミッションを変更します.
```
$ chmod 700 [キーペア名].pem
```
作成したインスタンスのElastic IPに接続します.
```
$ ssh -i [キーペア名].pem ec2-user@[Elastic IPアドレス]
```
を実行すると
```
The authenticity of host '[Elastic IPアドレス]' can't be established.
ECDSA key fingerprint is [鍵の内容].
Are you sure you want to continue connecting (yes/no)?
```
と出るので, `yes`と打ち接続します.

3. 管理者としてログインします.
```
[ec2-user@ ~]$ sudo su -
[root@ ~]#
```
LAMP環境構築のためのスクリプトを実行します.
```
[root@ ~]# bash wordpress.sh
```
`wordpress.sh`の内容は以下の通りです. vim等のエディタで貼り付けてファイルを作成してください.
```
amazon-linux-extras install php7.2
yum localinstall https://dev.mysql.com/get/mysql80-community-release-el7-1.noarch.rpm -y
yum-config-manager --disable mysql80-community
yum-config-manager --enable mysql57-community
yum install -y httpd php mysql-community-server
systemctl start httpd mysqld
systemctl enable mysqld httpd
cd /var/www/html/
wget https://ja.wordpress.org/latest-ja.tar.gz
tar -xzvf latest-ja.tar.gz
rm latest-ja.tar.gz
```
何度か実行するかどうかの確認が表示されますが, すべて`y`と入力し進めてください.

4. `/var/www/html/wordpress`以下にWordPressでサイトを表示するのに必要なファイルがダウンロードされました.<br>
サーバへのアクセスから自動的にここに飛ばすために, ドキュメントルートを変更します(最後の行のみ変更).
```
[root@ ~]# vim /etc/httpd/conf/httpd.conf
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# DocumentRoot: The directory out of which you will serve your
# documents. By default, all requests are taken from this directory, but
# symbolic links and aliases may be used to point to other locations.
#
DocumentRoot "/var/www/html/wordpress"
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
```
これでWordPressの環境構築は終了です.

## 3. WordPressの設定
1. サーバのデータベース(DB)はMySQLによって管理します.<br>
ログから初期パスを確認します.
```
[root@ ~]# cat /var/log/mysqld.log | grep "localhost"
[] [Note] A temporary password is generated for root@localhost: [初期パスワード]
```
このパスを用いてSQLにログインし, DBの設定をします.
```
[root@ ~]# mysql -uroot -p
[初期パスワードを入力]
mysql> ALTER USER 'root'@'localhost' IDENTIFIED BY 'Defaultp@ssw0rd';
mysql> CREATE DATABASE wpa001;
mysql> CREATE USER wpa001@localhost IDENTIFIED BY 'Hogehoge@1234';
mysql> GRANT ALL ON wpa001.* TO wpa001@localhost IDENTIFIED BY 'Hogehoge@1234';
mysql> FLUSH PRIVILEGES;
mysql> quit
```
ここで<br>
`Defaultp@ssw0rd` : SQLログインパスワード<br>
`wpa001` : DB名, ユーザー名<br>
`Hogehoge@1234` : DBのパスワード<br>
です. これは適当に決めたものなので好きなものに変えてください.<br>
ただし, **大文字,小文字, 数字, 記号を含む**必要があります.

2. ブラウザからサーバの**Elastic IP**に接続してみましょう.<br>
WordPressインストールの画面が表示されるはずです.<br>
されない場合は`[Elastic IPアドレス]/wordpress`と打ってください.<br>
<br>
データベース名　　　　 : wpa001(先程決めたDB名)<br>
ユーザー名　　　　　　 :  wpa001(先程決めたユーザー名)<br>
パスワード　　　　　　 : Hogehoge@1234(DBのパスワード)<br>
データベースのホスト名 : localhost<br>
テーブル接頭辞　　　　 : wp000_(データベースの中身の名前が変わります.ここも適当に)

3. **送信**を押すとWebサイトのインストールが始まります.<br>
もし
`ファイル wp-config.php に書き込めませんでした。`<br>
と出るようなら以下のように自分で作成します.
```
[root@ ~]# vim /var/www/html/wordpress/wp-config.php
[ブラウザに表示されたソースコードを貼り付けて保存]
```
**インストールを実行**からサイトの諸々を設定し, 終了です.
