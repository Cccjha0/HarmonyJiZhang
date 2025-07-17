import { router } from '@kit.ArkUI'

@Entry
@Component
struct UpdatePage {
  build() {
    Scroll() { //
      Column() {
        // 顶部标题栏
        Row() {
          Image($r('app.media.back')).width(35).height(35).margin({ left: 15, right: 10 })
            .onClick(() => {
              router.back();
            })
          Text('常见问题')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
        }
        .margin({ top: 20, bottom: 10, left: 10 })
        .width('100%')

        // 日期分组：2025年7月17日
        Text('最近的问题')
          .fontSize(14)
          .fontColor('#888')
          .margin({ top: 30, bottom: 6, left: 0 })

        this.commitItem('如何添加新的账单？', '点击首页右下角的“记一笔”按钮，填写信息后保存即可。')
        this.commitItem('数据会同步到云端吗？', '当前数据只保存在本地，确保您的隐私安全。')
        this.commitItem('如何查看月度统计？', '在底部导航栏切换到“统计”页面，可以看到月度汇总。')
        this.commitItem('可以自定义头像和名称吗？', '是的，您可以在关于中更改。')
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f5f5')
  }

  @Builder
  commitItem(title: string, author: string) {
    Column() {
      Text(title)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(Color.Black)
        .margin({ bottom: 4 })

      Text(`${author} `)
        .fontSize(12)
        .fontColor('#666')
    }
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor('#ffffff')
    .width('100%')
    .margin({ bottom: 10 })
  }
}
