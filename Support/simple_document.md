# Simple Document

## Introduction: detectGesture() is a wrapper of SpatialEventGesture (Official API).

```swift
// SpatialEventGesture (Official API)
SomeView()
    .gesture(
        SpatialEventGesture()
            .onChanged { eventCollection in // : SpatialEventCollection

            }
            .onEnded { eventCollection in

            }
    )
)
```

```swift
// detectGesture()
SomeView()
    .detectGesture(
        MyGesture.self,
        detect: { state in // : DetectGestureState

        },
        handle: { state in

        }
    )
)
```

`SpatialEventGesture`はマルチフィンガージェスチャを扱うための公式APIである([doc](https://developer.apple.com/documentation/swiftui/spatialeventgesture))。  
`detectGesture()`はその`SpatialEventGesture`のラッパーである。  

`detectGesture()`は内部で`SpatialEventGesture`を監視して、onChangedやonEndedが呼ばれた時に`detect: {}`や`handle: {}`などをコールしている。  
渡される新しい値(`SpatialEventCollection`)は、`DetectGestureValue`でラップされ、`DetectGestureState`内の`gestureValues: [DetectGestureTouchSequence.Value]`プロパティに格納され、クロージャの引数として渡される。

## SpatialEventGesture (Official API)の仕様

TODO: 図

- `SpatialEventCollection`: その時点での指ごとのジェスチャ情報である`[SpatialEventCollection.Event]`を格納している。
- `SpatialEventCollection.Event`: 指一本の情報。idを持っていて同じ指なら同じ値になる。
  - [注意] idの一意性は同じシークエンス内でのみ保証されます。異なるシークエンスでは同じ値が使いまわされる可能性があります。
- [注意] 指が動いていない間はonUpdated/onEndedは呼ばれません。

## DetectGesture (This API)

TODO: 図

- `DetectGestureTouchSequence.Value`: `SpatialEventCollection` + 独自の追加情報です。詳細は[定義](../Sources/Feature/DetectGesture/State/GesutureValue/DetectGestureValue.swift)を確認してください。
- `DetectGestureTouchSequence`: 一つのシークエンス。`[DetectGestureTouchSequence.Value]`を格納する。
- `SpatialEventGesture`と違い指が止まっている間も新しい値が生成され、`detect: {}`や`handle: {}`などをコールします。

## 変換 Utilities

`detectGesture()`のクロージャで渡される`DetectGestureState`は`gestureValues: [DetectGestureTouchSequence.Value]`プロパティにタップ情報を格納している。そのままで使いにくい場合は以下のようなユーティリティ型に変換してから使うと良い。

### シークエンスごとにまとめる

`[DetectGestureTouchSequence]`に変換できる。

### 指ごとにまとめる

TODO: 図

- 指ごとに情報を整理した`[DetectGestureFingerSequence]`型に変換できる。
- 便利なのでこの型に変換してから使うことが多そう。
- `DetectGestureFingerSequence`, `DetectGestureFingerSequence.Finger`, `DetectGestureFingerSequence.Finger.Event`: 図に示す通り。

### ピンチ用に変換

- ピンチジェスチャ用に`[DetectGesturePinchCollection]`型に変換できる。

### その他の変換

必要そうなのは作った。
