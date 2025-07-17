import { BillRecord } from '../common/models/Bill'
import { billService,accountService } from '../common/AppServiceRegistry'
import router from '@ohos.router'

interface RouteParams {
  paymentType: string
}

@Entry
@Component
export struct PaymentDetailPage {
  @State bills: BillRecord[] = []
  @State isLoading: boolean = true
  @State totalIncome: number = 0
  @State totalExpense: number = 0
  @State paymentType: string = ''

  aboutToAppear() {
    try {
      const params = router.getParams() as RouteParams
      this.paymentType = params?.paymentType ?? '未知账户'
    } catch (error) {
      console.error('Failed to get route params:', error)
      this.paymentType = '未知账户'
    }
    this.loadBills()
  }

  onBackPress() {
    router.back()
    return true
  }

  async loadBills() {
    try {
      // 获取所有账单
      const allBills = await billService.getAllBills()

      // 获取对应支付方式的 accountId
      let accountId = -1
      try {
        const account = await accountService.getAccountByName(this.paymentType)
        console.debug("get:" + account.id)
        accountId = account.id
      } catch (err) {
        console.error(`无法获取账户 ${this.paymentType}:`, err.message)
      }

      if (accountId === -1) {
        this.bills = []
        this.totalIncome = 0
        this.totalExpense = 0
        return
      }
      
      // 根据accountId过滤特定支付方式的账单
      this.bills = allBills.filter(bill => {
        return bill.accountId === accountId
      })

      // 计算总收入和支出
      this.totalIncome = this.bills
        .filter(bill => bill.type === '收入')
        .reduce((sum, bill) => sum + bill.amount, 0)
      
      this.totalExpense = this.bills
        .filter(bill => bill.type === '支出')
        .reduce((sum, bill) => sum + bill.amount, 0)
    } catch (error) {
      console.error('Failed to load bills:', error.message)
    } finally {
      this.isLoading = false
    }
  }

  @Builder
  BillItem(bill: BillRecord) {
    Row() {
      Column() {
        Text(bill.category)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
        Text(bill.date)
          .fontSize(12)
          .fontColor('#999999')
        if (bill.remark) {
          Text(bill.remark)
            .fontSize(12)
            .fontColor('#999999')
        }
      }
      .alignItems(HorizontalAlign.Start)

      Blank()

      Text(`${bill.type === '支出' ? '-' : '+'}¥${bill.amount.toFixed(2)}`)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(bill.type === '支出' ? '#00CC00' : '#FF0000')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
  }

  build() {
    Column() {
      // 顶部标题栏
      Row() {
        Image($r('app.media.back'))
          .width(24)
          .height(24)
          .onClick(() => {
            this.onBackPress()
          })
        Text(this.paymentType)
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .margin({ left: 16 })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .backgroundColor("#FFFFFF")

      // 收支统计
      Row() {
        Column() {
          Text('收入')
            .fontSize(14)
            .fontColor('#666666')
          Text(`¥${this.totalIncome.toFixed(2)}`)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FF0000')
            .margin({ top: 4 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)

        Divider()
          .vertical(true)
          .height(40)
          .color('#E0E0E0')

        Column() {
          Text('支出')
            .fontSize(14)
            .fontColor('#666666')
          Text(`¥${this.totalExpense.toFixed(2)}`)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#00CC00')
            .margin({ top: 4 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .padding(16)
      .backgroundColor(Color.White)
      .margin({ bottom: 12 })

      // 账单列表
      List() {
        ForEach(this.bills, (bill: BillRecord) => {
          ListItem() {
            this.BillItem(bill)
          }
        })
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8F8F8')
  }
} 