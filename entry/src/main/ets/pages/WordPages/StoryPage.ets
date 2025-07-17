import { router } from '@kit.ArkUI';

@Entry
@Component
struct StoryPage {
  @State message: string = 'SugarLife 是一个简洁而温暖的记账本，旨在帮你记录每一笔花销与收入，守护你生活的每一个细节。';

  build() {
    Scroll() {
      Column() {
        // 顶部标题栏
        Row() {
          Image($r('app.media.back'))
            .width(30)
            .height(30)
            .margin({ left: 15, right: 10 })
            .onClick(() => {
              router.back();
            });
          Text('产品故事')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#222');
        }
        .margin({ top: 24, bottom: 20, left: 15, right: 15 })
        .width('100%')
        .alignItems(VerticalAlign.Center);

        // 简介段落
        Text(this.message)
          .fontSize(16)
          .lineHeight(28)
          .fontColor('#444')
          .margin({ left: 15, right: 15, bottom: 30 });

        // 特点小标题和内容
        Text('🧊 我们的初衷')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#111')
          .margin({ left: 15, bottom: 10 });

        Text('在快节奏的生活中，许多人难以持续记账，我们希望通过简洁的设计和温暖的交互，帮助你坚持记录生活。')
          .fontSize(15)
          .lineHeight(26)
          .fontColor('#555')
          .margin({ left: 15, right: 15, bottom: 30 });

        Text('🍯 我们的特色')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#111')
          .margin({ left: 15, bottom: 10 });

        Column() {
          this.featureItem('🌈 极简设计，轻松操作');
          this.featureItem('📅 支持日历查看和月度统计');
          this.featureItem('🔒 本地存储，数据安全私密');
          this.featureItem('📷 自定义分类图标和样式');
        }
        .margin({ left: 15, right: 15, bottom: 30 });

        Text('🍃 我们希望')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#111')
          .margin({ left: 15, bottom: 10 });

        Text('SugarLife 不止是一款工具，而是你生活的一部分，愿你在每一次记录中，感受到秩序与温度。')
          .fontSize(15)
          .lineHeight(26)
          .fontColor('#555')
          .margin({ left: 15, right: 15, bottom: 50 });
      }
      .width('100%')
      .height('100%');
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#fafafa')
  }

  @Builder
  featureItem(text: string) {
    Text(text)
      .fontSize(15)
      .fontColor('#333')
      .margin({ bottom: 10 })
  }
}
