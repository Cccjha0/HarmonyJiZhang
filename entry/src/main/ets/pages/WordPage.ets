import { router } from "@kit.ArkUI"

@Entry
@Component
export default struct WordPage{
  @StorageLink('username') username: string = '未登录用户';
  @StorageLink('avatarPath') avatarPath: string = 'app.media.default_avatar';


  build() {
    Column({ space: 20 }) {

      // 用户头像 + 名称
      Row() {
        Image(this.avatarPath.startsWith('app.media') ? $r(this.avatarPath) : this.avatarPath)
          .width(60)
          .height(60)
          .borderRadius(30)
          .margin({ right: 20 })
        Column() {
          Text(this.username)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
          Text('点击修改资料')
            .fontSize(14)
            .fontColor('#888')
        }.alignItems(HorizontalAlign.Start)
        .onClick(() => {
          // 模拟打开资料编辑页面（可自定义）
          router.pushUrl({
            url: "pages/WordPages/UserPage"
          });
        })
      }
      .padding(20)
      .width('100%')
      .backgroundColor('#f0f0f0')
      .borderRadius(12)

      // 菜单项
      this.menuItem($r('app.media.sugarlife0'), '产品故事', () => {
        router.pushUrl({
          url: "pages/WordPages/StoryPage"
        });
      })

      this.menuItem($r('app.media.sugarlife1'), '更新日志', () => {
        router.pushUrl({
          url: "pages/WordPages/UpdatePage"
        });
      })

      this.menuItem($r('app.media.sugarlife2'), '常见问题', () => {
        router.pushUrl({
          url: "pages/WordPages/QuestionPage"
        });
      })

      this.menuItem($r('app.media.sugarlife3'), '联系开发者', () => {
        router.pushUrl({
          url: "pages/WordPages/AssociationPage"
        });
      })
    }
    .padding(16)
    .backgroundColor('#ffffff')
    .width('100%')
    .height('100%')
  }

  // 单项构建器
  @Builder
  menuItem(icon: Resource, title: string, onClick: () => void) {
    Row({ space: 10 }) {
      // 左侧图标 + 文本组合
      Row() {
        Image(icon)
          .width(24)
          .height(24)
          .borderRadius(6)

        // 空白 Spacer 控制间距
        Blank().width(12)

        Text(title)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(Color.Black)
      }
      .alignItems(VerticalAlign.Center)

    }
    .justifyContent(FlexAlign.SpaceBetween)
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .width('100%')
    .onClick(onClick)
  }


}