import { router } from '@kit.ArkUI';

@Entry
@Component
struct TryPage {
  @State message: string = '····这是一个测试界面····';

  build() {
    RelativeContainer() {

      Row(){
        Image($r('app.media.back')).width(35).height(35).margin({left:15,right:10})
          .onClick(()=>{
            router.back()
          })
        Text('添加账单').fontSize(20).fontWeight(600)
      }.justifyContent(FlexAlign.Start)
      .width('100%')
      .margin({bottom:20,top:15,left:10})

      Text(this.message)
        .id('TryPageHelloWorld')
        .fontSize($r('app.float.page_text_font_size'))
        .fontWeight(FontWeight.Bold)
        .alignRules({
          center: { anchor: '__container__', align: VerticalAlign.Center },
          middle: { anchor: '__container__', align: HorizontalAlign.Center }
        })
        .onClick(() => {
          this.message = 'Welcome';
        })
    }
    .height('100%')
    .width('100%')
  }
}