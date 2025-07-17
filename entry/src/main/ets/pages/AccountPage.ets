import { Account } from '../common/models/Account'
import { accountService } from '../common/AppServiceRegistry'
import { Bill } from '../common/models/Bill'
import promptAction from '@ohos.promptAction'
import router from '@ohos.router'

interface RouteParams {
  paymentType: string
}

@Entry
@Component
export struct AccountPage {
  @State searchText: string = ''
  @State totalAssets: number = 0
  @State totalLiabilities: number = 0
  @State netAssets: number = 0
  @State isAssetsVisible: boolean = true
  private searchController: SearchController = new SearchController()

  @State isExpanded: Record<string, boolean> = {
    '现金': true,
    '银行卡': true,
    '信用卡': true,
    '支付宝': true,
    '微信': true
  }

  private paymentTypes: string[] = ['现金', '银行卡', '信用卡', '支付宝', '微信']
  @State filteredTypes: string[] = []

  aboutToAppear() {
    this.filteredTypes = this.paymentTypes
  }

  handleSearch(text: string): void {
    this.searchText = text
    if (!text) {
      this.filteredTypes = this.paymentTypes
      return
    }
    this.filteredTypes = this.paymentTypes.filter(type => 
      type.toLowerCase().includes(text.toLowerCase())
    )
  }

  formatBalance(balance: number): string {
    return `${balance >= 0 ? '' : '-'}¥${Math.abs(balance).toFixed(2)}`
  }

  toggleExpand(type: string): void {
    this.isExpanded[type] = !this.isExpanded[type]
  }

  async navigateToDetail(type: string) {
    try {
      const params: RouteParams = {
        paymentType: type
      }
      await router.pushUrl({
        url: 'pages/PaymentDetailPage',
        params: params
      })
    } catch (error) {
      console.error('Navigation failed:', error)
      promptAction.showToast({
        message: '页面跳转失败',
        duration: 2000
      })
    }
  }

  @Builder
  PaymentMethodGroup(type: string) {
    Column() {
      // 支付方式标题和展开/收起按钮
      Row() {
        Text(type)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
        Blank()
        Text(this.isExpanded[type] ? '收起' : '展开')
          .fontSize(14)
          .fontColor('#666666')
      }
      .width('100%')
      .padding(12)
      .backgroundColor('#F5F5F5')
      .onClick(() => this.toggleExpand(type))

      if (this.isExpanded[type]) {
        // 子项
        Column() {
          // 主账户项
          Button() {
            Row() {
              Text(type)
                .fontSize(14)
              Blank()
              Text('¥0.00')
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
            }
            .width('100%')
            .padding(12)
          }
          .width('100%')
          .backgroundColor(Color.White)
          .onClick(() => {
            this.navigateToDetail(type)
          })

          // 信用卡特殊显示
          if (type === '信用卡') {
            Row() {
              Column() {
                Text('本期账单')
                  .fontSize(12)
                  .fontColor('#999999')
                Text('¥0.00')
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium)
              }
              .alignItems(HorizontalAlign.Start)

              Blank()

              Column() {
                Text('可用额度')
                  .fontSize(12)
                  .fontColor('#999999')
                Text('¥20,000.00')
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium)
              }
              .alignItems(HorizontalAlign.End)
            }
            .width('100%')
            .padding(12)
            .backgroundColor(Color.White)
          }
        }
        .width('100%')
      }
    }
    .margin({ bottom: 12 })
  }

  build() {
    Column() {
      // 顶部标题栏
      Row() {
        Text('账户')
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
        Blank()
        Button() {
          Image($r('app.media.add'))
            .width(24)
            .height(24)
        }
        .backgroundColor(Color.Transparent)
        .margin({ right: 8 })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })

      Column() {
        // 搜索框
        Row() {
          Search({
            value: this.searchText,
            placeholder: '输入任意文字搜索账户',
            controller: this.searchController
          })
          .width('100%')
          .height(40)
          .backgroundColor('#F5F5F5')
          .placeholderColor('#999999')
          .placeholderFont({ size: 14 })
          .textFont({ size: 14 })
          .onChange((value: string) => this.handleSearch(value))
        }
        .padding({ left: 16, right: 16, top: 8, bottom: 8 })

        // 如果有搜索文本，直接显示搜索结果
        if (this.searchText) {
          Column() {
            ForEach(this.filteredTypes, (type: string) => {
              this.PaymentMethodGroup(type)
            })
          }
          .padding({ left: 16, right: 16 })
        }
      }

      if (!this.searchText) {
        // 资产统计卡片
        Row() {
          Column() {
            Row() {
              Text('净资产')
                .fontSize(14)
                .fontColor('#666666')
              Image($r('app.media.bx_sl'))
                .width(20)
                .height(20)
                .margin({ left: 4 })
                .onClick(() => {
                  this.isAssetsVisible = !this.isAssetsVisible
                })
            }

            Text(this.isAssetsVisible ? '¥0.00' : '****')
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .margin({ top: 4 })

            Row() {
              Text(`资产 ${this.isAssetsVisible ? '¥0.00' : '****'}`)
                .fontSize(12)
                .fontColor('#666666')
              Text(`  负债 ${this.isAssetsVisible ? '¥0.00' : '****'}`)
                .fontSize(12)
                .fontColor('#666666')
            }
            .margin({ top: 8 })
          }
          .width('100%')
          .padding(16)
          .backgroundColor(Color.White)
          .borderRadius(8)
        }
        .padding({ left: 16, right: 16, top: 8, bottom: 8 })

        // 支付方式列表
        Scroll() {
          Column() {
            ForEach(this.paymentTypes, (type: string) => {
              this.PaymentMethodGroup(type)
            })
          }
          .width('100%')
          .padding({ left: 16, right: 16 })
        }
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8F8F8')
  }
} 