import { router } from '@kit.ArkUI';

@Entry
@Component
struct AssociationPage {
  @State message: string = 'GitHub 项目地址：\nhttps://github.com/Cccjha0/HarmonyJiZhang/';

  build() {
    RelativeContainer() {
      Row() {
        Image($r('app.media.back'))
          .width(35)
          .height(35)
          .margin({ left: 15, right: 10 })
          .onClick(() => {
            router.back();
          });
        Text('联系开发者')
          .fontSize(20)
          .fontWeight(FontWeight.Bold);
      }
      .justifyContent(FlexAlign.Start)
      .width('100%')
      .margin({ bottom: 20, top: 5, left: 10 });

      Text(this.message)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(Color.Black)
        .textAlign(TextAlign.Center)
        .alignRules({
          center: { anchor: '__container__', align: VerticalAlign.Center },
          middle: { anchor: '__container__', align: HorizontalAlign.Center }
        })
        .onClick(() => {
          this.message = '感谢关注项目！';
        })
        .width('80%')
        .lineHeight(22)
        .margin({ left: 'auto', right: 'auto' });
    }
    .height('100%')
    .width('100%');
  }
}
