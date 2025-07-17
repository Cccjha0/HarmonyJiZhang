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
        }
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
      this.menuItem($r('app.media.add'), '产品故事', () => {
        router.pushUrl({
          url: "pages/WordPages/StoryPage"
        });
      })

      this.menuItem($r('app.media.add'), '更新日志', () => {
        router.pushUrl({
          url: "pages/WordPages/UpdatePage"
        });
      })

      this.menuItem($r('app.media.add'), '常见问题', () => {
        router.pushUrl({
          url: "pages/WordPages/QuestionPage"
        });
      })

      this.menuItem($r('app.media.add'), '联系开发者', () => {
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
    Row({ space: 8 }) {
      // 左侧图标 + 文本
      Row() {
        Image(icon)
          .width(24)
          .height(24)
          .margin({ right: 12 })
        Text(title)
          .fontSize(18)
      }

      // 右侧箭头图标
      Image($r('app.media.add'))
        .width(16)
        .height(16)
    }
    .justifyContent(FlexAlign.SpaceBetween)
    .padding(12)
    .width('100%')
    .onClick(onClick)
  }

}