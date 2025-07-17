import { Account, AccountRecord } from '../common/models/Account'
import { accountService } from '../common/AppServiceRegistry'
import { Bill } from '../common/models/Bill'
import promptAction from '@ohos.promptAction'
import router from '@ohos.router'

interface RouteParams {
  paymentType: string
}

interface PaymentCategory {
  name: string
  types: string[]
}

@CustomDialog
struct AddPaymentMethodDialog {
  private paymentCategories: PaymentCategory[] = [
    {
      name: '现金账户',
      types: ['现金']
    },
    {
      name: '银行账户',
      types: ['银行卡', '信用卡']
    },
    {
      name: '电子支付',
      types: ['支付宝', '微信']
    }
  ]
  controller: CustomDialogController
  onSelect: (type: string) => void = () => {}

  build() {
    Column() {
      Text('添加账户')
        .fontSize(20)
        .fontWeight(FontWeight.Medium)
        .margin({ bottom: 16 })

      ForEach(this.paymentCategories, (category: PaymentCategory) => {
        Column() {
          Text(category.name)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 8 })

          ForEach(category.types, (type: string) => {
            Button() {
              Row() {
                Text(type)
                  .fontSize(14)
                Blank()
                Image($r('app.media.add'))
                  .width(20)
                  .height(20)
              }
              .width('100%')
              .padding(12)
            }
            .width('100%')
            .backgroundColor(Color.White)
            .margin({ bottom: 8 })
            .onClick(() => {
              this.controller.close()
              this.onSelect(type)
            })
          })
        }
        .margin({ bottom: 16 })
      })

      Button('取消')
        .width('100%')
        .backgroundColor('#F5F5F5')
        .fontColor('#666666')
        .onClick(() => {
          this.controller.close()
        })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius({ topLeft: 16, topRight: 16 })
  }
}

@Entry
@Component
export struct AccountPage {
  @State searchText: string = ''
  @State totalAssets: number = 0
  @State totalLiabilities: number = 0
  @State netAssets: number = 0
  @State isAssetsVisible: boolean = true
  @State accounts: AccountRecord[] = []
  private searchController: SearchController = new SearchController()
  private addDialogController: CustomDialogController = new CustomDialogController({
    builder: AddPaymentMethodDialog({
      onSelect: (type: string): void => {
        this.handlePaymentTypeSelect(type)
      }
    }),
    customStyle: true,
    alignment: DialogAlignment.Bottom
  })

  @State isExpanded: Record<string, boolean> = {}
  @State filteredAccounts: AccountRecord[] = []

  async aboutToAppear(): Promise<void> {
    await this.loadAccounts()
  }

  async loadAccounts(): Promise<void> {
    try {
      // 获取所有账户及其余额
      const accounts = await accountService.getAllAccountsWithBalance()
      console.info(`[Debug] 加载到 ${accounts.length} 个账户:`)
      accounts.forEach(account => {
        console.info(`[Debug] 账户: ${account.name}, 类型: ${account.type}, ID: ${account.id}, 余额: ${account.balance}`)
      })
      this.accounts = accounts

      // 计算总资产和负债
      let assets = 0
      let liabilities = 0
      accounts.forEach(account => {
        if (account.balance) {
          if (account.balance >= 0) {
            assets += account.balance
          } else {
            liabilities += Math.abs(account.balance)
          }
        }
      })

      this.totalAssets = assets
      this.totalLiabilities = liabilities
      this.netAssets = assets - liabilities
      console.info(`[Debug] 总资产: ${assets}, 总负债: ${liabilities}, 净资产: ${this.netAssets}`)

      // 更新搜索结果
      if (this.searchText) {
        this.handleSearch(this.searchText)
      } else {
        this.filteredAccounts = this.accounts
      }
    } catch (error) {
      console.error('[Debug] 加载账户失败:', error)
      promptAction.showToast({
        message: '加载账户失败',
        duration: 2000
      })
    }
  }

  handleSearch(text: string): void {
    this.searchText = text
    if (!text) {
      this.filteredAccounts = this.accounts
      return
    }
    this.filteredAccounts = this.accounts.filter(account => 
      account.name.toLowerCase().includes(text.toLowerCase()) ||
      account.type.toLowerCase().includes(text.toLowerCase())
    )
  }

  formatBalance(balance: number): string {
    return `${balance >= 0 ? '' : '-'}¥${Math.abs(balance || 0).toFixed(2)}`
  }

  toggleExpand(type: string): void {
    this.isExpanded[type] = !this.isExpanded[type]
  }

  private async handlePaymentTypeSelect(type: string): Promise<void> {
    // 检查是否已存在相同类型的支付方式
    const exists = this.accounts.some(account => account.type === type)
    if (exists) {
      console.info(`[Debug] 账户类型 ${type} 已存在，不能重复添加`)
      promptAction.showToast({
        message: '该类型账户已存在',
        duration: 2000
      })
      return
    }

    try {
      // 创建新账户
      const accountName = type // 可以后续让用户自定义名称
      console.info(`[Debug] 开始创建账户: ${accountName}, 类型: ${type}`)
      const id = await accountService.createAccount(accountName, type)
      
      if (id === -1) {
        console.error(`[Debug] 创建账户失败，返回ID: ${id}`)
        promptAction.showToast({
          message: '添加账户失败',
          duration: 2000
        })
        return
      }

      console.info(`[Debug] 创建账户成功，ID: ${id}`)

      // 重新加载账户列表
      await this.loadAccounts()

      // 展开新添加的账户
      this.isExpanded[type] = true

      promptAction.showToast({
        message: '添加成功',
        duration: 2000
      })
    } catch (error) {
      console.error('[Debug] 创建账户失败:', error)
      promptAction.showToast({
        message: '添加账户失败',
        duration: 2000
      })
    }
  }

  private async navigateToDetail(account: AccountRecord): Promise<void> {
    try {
      await router.pushUrl({
        url: 'pages/PaymentDetailPage',
        params: {
          accountId: account.id,
          paymentType: account.type
        }
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
  AccountItem(account: AccountRecord): void {
    Column() {
      // 支付方式标题和展开/收起按钮
      Row() {
        Text(account.name)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
        Blank()
        Text(this.isExpanded[account.type] ? '收起' : '展开')
          .fontSize(14)
          .fontColor('#666666')
      }
      .width('100%')
      .padding(12)
      .backgroundColor('#F5F5F5')
      .onClick(() => this.toggleExpand(account.type))

      if (this.isExpanded[account.type]) {
        // 子项
        Column() {
          // 主账户项
          Button() {
            Row() {
              Text(account.name)
                .fontSize(14)
              Blank()
              Text(this.formatBalance(account.balance || 0))
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
            }
            .width('100%')
            .padding(12)
          }
          .width('100%')
          .backgroundColor(Color.White)
          .onClick(() => {
            this.navigateToDetail(account)
          })

          // 信用卡特殊显示
          if (account.type === '信用卡') {
            Row() {
              Column() {
                Text('本期账单')
                  .fontSize(12)
                  .fontColor('#999999')
                Text('¥0.00') // 这里需要从数据库获取实际账单
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium)
              }
              .alignItems(HorizontalAlign.Start)

              Blank()

              Column() {
                Text('可用额度')
                  .fontSize(12)
                  .fontColor('#999999')
                Text('¥20,000.00') // 这里需要从数据库获取实际额度
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

  @Builder
  EmptyState(): void {
    Column() {
      Image($r('app.media.add'))
        .width(48)
        .height(48)
        .opacity(0.5)
        .margin({ bottom: 16 })
      Text('暂无账户')
        .fontSize(16)
        .fontColor('#999999')
      Text('点击右上角添加账户开始记账')
        .fontSize(14)
        .fontColor('#999999')
        .margin({ top: 8 })
    }
    .width('100%')
    .height('60%')
    .justifyContent(FlexAlign.Center)
  }

  build(): void {
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
        .onClick(() => {
          this.addDialogController.open()
        })
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
        if (this.searchText && this.filteredAccounts.length > 0) {
          Column() {
            ForEach(this.filteredAccounts, (account: AccountRecord) => {
              this.AccountItem(account)
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

            Text(this.isAssetsVisible ? this.formatBalance(this.netAssets) : '****')
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .margin({ top: 4 })

            Row() {
              Text(`资产 ${this.isAssetsVisible ? this.formatBalance(this.totalAssets) : '****'}`)
                .fontSize(12)
                .fontColor('#666666')
              Text(`  负债 ${this.isAssetsVisible ? this.formatBalance(this.totalLiabilities) : '****'}`)
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

        // 支付方式列表或空状态
        if (this.accounts.length > 0) {
          Scroll() {
            Column() {
              ForEach(this.accounts, (account: AccountRecord) => {
                this.AccountItem(account)
              })
            }
            .width('100%')
            .padding({ left: 16, right: 16 })
          }
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.Spring)
          .layoutWeight(1)
        } else {
          this.EmptyState()
        }
      }
    }
  }
} 