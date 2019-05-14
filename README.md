# aseprite-scripts

## このスクリプトについて

マスクレイヤー機能がないAsepriteに、マスクレイヤー  **ぽい**  機能を追加するスクリプトです。

コピペ機能を使って、エクスポートレイヤーにマスクレイヤーで指定した範囲を切り出します。

（マスクの代わりに手動でやってきた作業を、多少楽にするため程度のツールです）

## インストール

Asepriteのメニューから```File > Scripts > Open Script Folder```で開いたディレクトリに```dMask Toolbar.lua```を格納するだけです。

Aseprite v1.2.10以上が必須です。

## 使い方

```File > Scripts > dMask Toolbar```を選択するとツールのダイアログが起動します。

### ツールダイアログ

![ダイアログ](https://github.com/masakazu-k/aseprite-scripts/blob/images/images/dialog01.png)

| | ボタン | 機能 |
| --- | --- | --- |
| Refresh || ビュー/タイムラインを更新する機能群 |
|| Active Frame | 現在選択されているフレームのエクスポートレイヤーを更新する |
|| All | 全フレームのエクスポートレイヤーを更新する機能 |
|| Sync Color | マスクレイヤーの色を対応するエクスポートレイヤーの色と揃える |
| Mask Layer || マスクレイヤーを設定する機能群 |
|| Set Mask | 選択されているレイヤー/セルをマスクに指定する |
|| Unset Mask | 選択されているレイヤー/セルのマスク指定を解除する |
|| Create New Mask | 未実装 |
| Export Layer || エクスポートレイヤーへの出力に関する設定 |
|| Setting | マスクレイヤーの出力形式を指定する |

### 基本的な使い方

任意の名前のマスクレイヤーを作成します(例では```mask_test```という名前を使用)。

マスクレイヤーを選択した状態で、ツールダイアログの```Set Mask```を押下します。
※セルで指定した場合、そのフレームでのみマスクが有効になります。

<img src="https://github.com/masakazu-k/aseprite-scripts/blob/images/images/usage01.png" width="300">

ダイアログが立ち上がるので、```OK```を押下します。

![usage](https://github.com/masakazu-k/aseprite-scripts/blob/images/images/usage02.png)

デフォルトのエクスポート（指定範囲切り出し先）がレイヤー```export_```が作成されます。

<img src="https://github.com/masakazu-k/aseprite-scripts/blob/images/images/usage03.png" width="300">

マスクレイヤーにマスク（切り出）したい範囲を塗りつぶします。色は何でもいいです。

<img src="https://github.com/masakazu-k/aseprite-scripts/blob/images/images/usage04.png" width="300">

マスクレイヤーを非表示にして、```Active Frame```か```All```を押下すると、指定範囲が切り出されます。

<img src="https://github.com/masakazu-k/aseprite-scripts/blob/images/images/usage05.png" width="300">

**エクスポートレイヤー**を指定して```Setting```を押下すると、切り出し方の設定ダイアログが出ます。

* ```Marged``` 下からマスクレイヤーまでの画像を合成（？）した状態での切り出し （塗りつぶしされている範囲）
* ```Inverse``` 下からマスクレイヤーまでの画像を合成（？）した状態での切り出し （塗りつぶしされていない範囲）
* ```Self``` 同一のエクスポートレイヤーを指定したマスクレイヤーのみを切り出し

### 補足事項

 あくまでエクスポートレイヤーにコピペで切り出しているだけなので、自動更新はされません。
 画像を更新したら、```Active Frame```か```All```を押下してください。

 ```export_```から始まるレイヤーはすべてエクスポートレイヤーとして認識します。
 複数のマスクレイヤーとエクスポートレイヤーを組み合わせて、ある程度までなら複雑な切り出し方に対応できる気がします。

 一度設定したエクスポートレイヤーを変える場合、```Set Mask```からプルダウンメニューで選択してください。
 
 マスクレイヤーを見失わないように、マスクレイヤーに同じ色を設定する機能があります。
 エクスポートレイヤーに色を指定して```Sync Color```を押下することで使用できます。
 
 複数エクスポートレイヤーがある場合は、それぞれの別の色を指定することで分かりやすくなると思います。

 あと```Refresh > All```は遅いです。

