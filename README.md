# Mask layer-like extensions for Aseprite

マスクレイヤー機能がないAsepriteに、マスクレイヤー  **ぽい**  機能を追加する拡張機能です。
マスクレイヤーで指定した領域をコピペ機能（MergedCopy）を使って切り出します。
（マスクの代わりに手動でやってきた作業を、多少楽にするため程度のツールです） 


This is an extension that adds the mask layer-**like** function to Aseprite.
Use the MergedCopy function to cut out the mask area specified in the mask layer.
(It is a tool to make the manual work a little easier.)

# インストール (Install)

[このページ](https://github.com/masakazu-k/aseprite-scripts/releases)から"mask-layer-like-extension.aseprite-extension"をDLして、ダブルクリックすることでインストールできます。

You can install it by downloading "mask-layer-like-extension.aseprite-extension" from [this page](https://github.com/masakazu-k/aseprite-scripts/releases) and double-clicking .

# 使い方 (Usage)

## マスクレイヤーを作る (Create Mask Layer)

タイムライン上でマスクしたいレイヤーを選択し、右クリックメニューから"New Mask Layer"を選択するとマスクレイヤー作成ダイアログが開きます。

To open the mask layer creation dialog, select the layer you want to mask on the timeline and select "New Mask Layer" from the right-click menu.

|  | 要素 | 説明 |
| --- | --- | --- |
| type || マスクレイヤーの種類を指定します。 |
| Export Layer (Copy to) || マスクした結果をペーストするレイヤー名を指定します。 |
| Source Layer (Copy from) || Include/Excludeを組み合わせて、マスク対象（コピー元）のレイヤー名を指定します。 |
|| Include Layers | マスク対象のレイヤー名を指定します。グループを指定した場合、全ての子レイヤーが対象になります。 |
|| Exclude Layers | マスク対象**外**のレイヤー名を指定します。Include Layersで指定したグループレイヤーの内、一部子レイヤーを対象外にしたい場合指定します。 |
| Apply || マスクレイヤーを作成／更新します。Export Layerが存在しない場合、同時に作成します。 |
| Cancel || マスクレイヤーを作成／更新をキャンセルします。 |
| Close || なにこれ。 |


| | Element | Description |
| --- | --- | --- |
| type || Specify the type of mask layer. |
| Export Layer (Copy to) || Specify the layer name to paste the masked result. |
| Source Layer (Copy from) || Specify the Include/Exclude layer names of the mask targets (copy sources). |
|| Include Layers | Specify the layer names to be masked. If you specify a group, all child layers will be targeted. |
|| Exclude Layers | Specify the layer names to be **NOT** masked. Use this, if you want to exclude some child layers from the group layers in "Include Layers". |
| Apply || Create/Update mask layer. If the Export Layer does not exist, it will be created at the same time. |
| Cancel || Cancels Creating/Updating the mask layer. |
| Close || What is this? |

## マスクを実行する (Do Mask)

マスク機能は自動で実行されません。
タイムライン上でExport Layerのフレーム（セル）を選択し、右クリックメニューから"Update (Copy & Paste)"を選択するとマスク結果がExport Layerにペーストされます。

The mask function is not automatically executed.
To paste the mask result to the Export Layer, Select the cells of the Export Layer on the timeline, and select "Update (Copy & Paste)" from the right-click menu.

## マスクレイヤーの種類 (Type of Mask Layer)

#### mask

マスクレイヤーで**色が塗られた領域**をExport Layerにコピーします。

Copy the **colored area** in a mask layer to the Export Layer.

#### imask

マスクレイヤーで**色が塗られていない領域**をExport Layerにコピーします。

Copy the **uncolored area** of a mask layer to the Export Layer.

#### merge

**全領域**をExport Layerにコピーします。

Copy the **entire area** to the Export Layer.

#### outline (Not yet implemented)

未実装

Not yet implemented