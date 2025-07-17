import { router } from '@kit.ArkUI'

@Entry
@Component
struct UpdatePage {
  build() {
    Scroll() { // ✅ 支持垂直滚动
      Column() {
        // 顶部标题栏
        Row() {
          Image($r('app.media.back')).width(35).height(35).margin({ left: 15, right: 10 })
            .onClick(() => {
              router.back();
            })
          Text('更新日志')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
        }
        .margin({ top: 20, bottom: 10, left: 10 })
        .width('100%')

        // 日期分组：2025年7月17日
        Text('Commits on Jul 17, 2025')
          .fontSize(14)
          .fontColor('#888')
          .margin({ bottom: 6, left: 16 })

        this.commitItem('statisticsPage支持环形图', 'ponder-er', '43 minutes ago')
        this.commitItem('faceid 1.0.0', 'w1j2h3', '1 hour ago')
        this.commitItem('faceid 1.0', 'w1j2h3', '1 hour ago')
        this.commitItem('feat: add account detail page', 'WAYNO10', '1 hour ago')
        this.commitItem('支持getBillsByOptions方法使用accountId查询', 'Ccqjha0', '1 hour ago')

        // 日期分组：2025年7月16日
        Text('Commits on Jul 16, 2025')
          .fontSize(14)
          .fontColor('#888')
          .margin({ top: 24, bottom: 6, left: 16 })

        this.commitItem('添加首页日历UI', 'Ccqjha0', '12 hours ago')
        this.commitItem('Accounting模块适配Account和accountService', 'Ccqjha0', '19 hours ago')
        this.commitItem('svg4补充', 'w1j2h3', '19 hours ago')
        this.commitItem('svg补充', 'w1j2h3', '19 hours ago')
        this.commitItem('添加Account和accountService类', 'Cccjha0', '19 hours ago')
        this.commitItem('菜单栏及图标优化', 'w1j2h3', '19 hours ago')
        this.commitItem('前端重构', 'w1j2h3', '19 hours ago')
        this.commitItem('后端重构', 'w1j2h3', '19 hours ago')


        // 日期分组：2025年7月15日
        Text('Commits on Jul 15, 2025')
          .fontSize(14)
          .fontColor('#888')
          .margin({ top: 24, bottom: 6, left: 16 })

        this.commitItem('try123', 'Ccqjha0', '23 hours ago')
        this.commitItem('Accounting模块适配Account和accountService', 'Ccqjha0', '24 hours ago')
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f5f5')
  }

  @Builder
  commitItem(title: string, author: string, time: string) {
    Column() {
      Text(title)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(Color.Black)
        .margin({ bottom: 4 })

      Text(`${author} committed ${time}`)
        .fontSize(12)
        .fontColor('#666')
    }
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor('#ffffff')
    .width('100%')
    .margin({ bottom: 10 })
  }
}
