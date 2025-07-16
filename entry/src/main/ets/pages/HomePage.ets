import { billService, statisticsService } from '../common/AppServiceRegistry';
import { BillRecord, CategoryStatItem, StatisticsOptions, StatisticsResult } from '../common/models/Bill';
import { promptAction } from '@kit.ArkUI';

@Entry
@Component
export default struct HomePage {

  @Prop currentIndex: number;
  @Prop bills: BillRecord[];
  @Prop statistics: StatisticsResult;
  @Prop categoryStats: CategoryStatItem[];
  @Prop currentStatType: '收入' | '支出';
  @Prop isLoading: boolean = true;
  // 年度统计相关状态
  @Prop yearlyStatistics: StatisticsResult;
  @Prop yearlyStats: CategoryStatItem[];
  @Prop selectedYear: number;
  @Prop yearList: number[];
  // 首页月份选择相关状态
  @Prop selectedDate: Date;
  @Prop selectedMonth: number;
  @Prop selectedMonthString: string; // 初始显示为"本月"
  // 月度统计页的月份选择器
  @State monthList: string[] = ["1月", "2月", "3月", "4月", "5月", "6月", "7月", "8月", "9月", "10月", "11月", "12月"];
  @Prop statsSelectedMonth: number = new Date().getMonth() + 1;
  // 跟踪统计页当前的标签页索引
  @Prop statsTabIndex: number;
  // 触发统计视图更新的计数器
  @Prop statsUpdateTrigger: number;

  aboutToAppear() {
    // 初始化年份列表（近5年）
    const currentYear = new Date().getFullYear();
    this.yearList = Array.from<number, number>({length: 5}, (_, i) => currentYear - i);
    this.selectedYear = currentYear;
  }

  onPageShow() {
    // 获取当前日期并更新状态
    const now = new Date();
    const currentYear = now.getFullYear();
    const currentMonth = now.getMonth() + 1;

    this.selectedDate = now;
    this.selectedMonth = currentMonth;
    this.statsSelectedMonth = currentMonth; // 统计页月份选择器同步更新
    this.statsTabIndex = 0; // 默认显示月度统计
    this.selectedMonthString = "本月"; // 初始显示为"本月"

    // 加载当月账单和统计数据
    this.loadBillsByMonth(currentYear, currentMonth);

    // 加载年度统计数据
    this.loadYearlyStatistics(this.selectedYear);

    // 加载月度统计数据
    this.loadMonthlyStatistics(currentYear, currentMonth);
  }

  async loadBills() {
    this.isLoading = true;
    try {
      // 获取当前年月
      const now = new Date();
      const year = now.getFullYear();
      const month = now.getMonth() + 1;

      // 构造当月开始和结束日期
      const startDate = `${year}-${String(month).padStart(2, '0')}-01`;
      const lastDay = new Date(year, month, 0).getDate(); // 当月最后一天
      const endDate = `${year}-${String(month).padStart(2, '0')}-${String(lastDay).padStart(2, '0')}`;

      console.info(`加载当月账单：${startDate} 至 ${endDate}`);

      // 使用日期范围过滤当月账单
      this.bills = await billService.getBillsByOptions({
        startDate: startDate,
        endDate: endDate,
        sortBy: 'date',
        sortOrder: 'desc'
      });

      console.info(`加载到${this.bills.length}条当月账单记录`);
    } catch (error) {
      console.error(`加载账单失败: ${JSON.stringify(error)}`);
    } finally {
      this.isLoading = false;
    }
  }

  async loadStatistics() {
    console.info('开始加载统计数据');
    // 获取当前年月
    const now = new Date();
    const year = now.getFullYear();
    const month = now.getMonth() + 1;

    // 构造当月开始和结束日期
    const startDate = `${year}-${String(month).padStart(2, '0')}-01`;
    const lastDay = new Date(year, month, 0).getDate(); // 当月最后一天
    const endDate = `${year}-${String(month).padStart(2, '0')}-${String(lastDay).padStart(2, '0')}`;

    try {
      // 获取当月总收支统计
      this.statistics = await statisticsService.getStatistics({
        startDate: startDate,
        endDate: endDate
      });
      console.info(`当月统计数据: 收入${this.statistics.totalIncome}, 支出${this.statistics.totalExpense}`);

      // 获取支出分类统计
      this.loadCategoryStats(this.currentStatType, { startDate, endDate });
    } catch (error) {
      console.error(`加载统计数据失败: ${JSON.stringify(error)}`);
    }
  }

  async loadCategoryStats(type: '收入' | '支出', dateRange?: StatisticsOptions) {
    this.currentStatType = type;

    // 更新月度统计数据
    this.categoryStats = await statisticsService.getCategoryStatistics(type, dateRange);

    // 如果是在统计页面，同时更新年度统计
    if (this.currentIndex === 1) {
      // 更新年度分类统计
      const yearStartDate = `${this.selectedYear}-01-01`;
      const yearEndDate = `${this.selectedYear}-12-31`;
      this.yearlyStats = await statisticsService.getCategoryStatistics(type, {
        startDate: yearStartDate,
        endDate: yearEndDate
      });
    }

    // 递增触发器，强制UI更新
    this.statsUpdateTrigger++;
  }

  async deleteBillItem(id: number) {
    promptAction.showDialog({
      title: '确认删除',
      message: '确定要删除这条账单记录吗？',
      buttons: [
        {
          text: '取消',
          color: '#666666'
        },
        {
          text: '删除',
          color: '#e84026'
        }
      ]
    })
      .then(result => {
        // 点击删除按钮
        if (result.index === 1) {
          billService.deleteBill(id).then(success => {
            if (success) {
              // 刷新数据，确保统计数据也被刷新
              this.loadBillsByMonth(this.selectedDate.getFullYear(), this.selectedDate.getMonth() + 1);
              // 更新年度统计（如果当前是在统计页面）
              if (this.currentIndex === 1) {
                this.loadYearlyStatistics(this.selectedYear);
              }
              promptAction.showToast({ message: '删除成功' });
            } else {
              promptAction.showToast({ message: '删除失败' });
            }
          });
        }
      })
  }

  // 构建账单列表项
  @Builder
  billItemBuilder(bill: BillRecord) {
    Row() {
      Column() {
        Text(bill.category)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 5 })
        Text(bill.date)
          .fontSize(12)
          .fontColor('#666')
      }
      .alignItems(HorizontalAlign.Start)
      .width('30%')

      Column() {
        Text(bill.remark || '无备注')
          .fontSize(14)
          .fontColor('#333')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.MARQUEE })
      }
      .width('34%')

      Column() {
        Text(`${bill.type === '支出' ? '-' : '+'}${bill.amount.toFixed(2)}`)
          .fontSize(16)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.MARQUEE })
          .fontWeight(FontWeight.Bold)
          .fontColor(bill.type === '支出' ? '#f53f3f' : '#07c160')
      }
      .width('25%')
      .margin({right:5})
      .alignItems(HorizontalAlign.End)


      Button({ type: ButtonType.Circle, stateEffect: true }) {
        Image($r('app.media.jianhao')).width(20).height(20)
      }
      .width(30)
      .height(30)
      .backgroundColor('#f0f0f0')
      .onClick(() => {
        this.deleteBillItem(bill.id);
      })

    }
    .width('100%')
    .padding(11)
    .borderRadius(15)
    .backgroundColor(Color.White)
    .margin({ bottom: 10 })
  }

  // 构建底部tab标签
  @Builder
  tabBuilder(title: string, targetIndex: number, selectedImg: Resource, normalImg: Resource) {
    Column() {
      Image(this.currentIndex === targetIndex ? selectedImg : normalImg)
        .size({ width: 30, height: 30 })
        .margin({
          bottom: 3
        })
      Text(title)
        .fontSize(12)
        .fontColor(this.currentIndex === targetIndex ? '#333' : '#a3a3a3')

    }
    .width('100%')
    .height(50)
    .justifyContent(FlexAlign.Center)
  }

  // 构建类别统计项
  @Builder
  categoryStatItem(item: CategoryStatItem, total: number) {
    Row() {
      Text(item.category)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .width('15%')

      Column() {
        Row() {
          // 进度条
          Row() {
            // 避免除以零错误，确保总额大于0
            Row()
              .width(`${total > 0 ? (item.total / total) * 100 : 0}%`)
              .height(10)
              .backgroundColor(this.currentStatType === '支出' ? '#f53f3f' : '#07c160')
              .borderRadius(10)
          }
          .width('80%')
          .height(10)
          .backgroundColor('#e0e0e0')
          .borderRadius(10)

          // 百分比
          Text(`${total > 0 ? ((item.total / total) * 100).toFixed(1) : '0.0'}%`)
            .fontSize(14)
            .fontColor('#666')
            .width('35%')
            .textAlign(TextAlign.End)
            .margin({left:10})
        }
        .width('100%')
      }
      .width('40%')

      Text(`￥${item.total.toFixed(2)}`)
        .fontSize(16)
        .fontColor(this.currentStatType === '支出' ? '#f53f3f' : '#07c160')
        .width('35%')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.MARQUEE })
        .margin({left:30})
        .textAlign(TextAlign.End)

    }
    .width('100%')
    .padding(10)
    .backgroundColor(Color.White)
    .borderRadius(8)
    .margin({ bottom: 10 })
  }

  // 加载年度统计数据
  async loadYearlyStatistics(year: number) {
    console.info(`开始加载${year}年度统计数据`);

    // 确保year是有效的数字
    const yearNum = Number(year);
    if (isNaN(yearNum)) {
      console.error('无效的年份');
      return;
    }

    // 构造年度开始和结束日期
    const startDate = `${yearNum}-01-01`;
    const endDate = `${yearNum}-12-31`;

    const options: StatisticsOptions = {
      startDate: startDate,
      endDate: endDate
    };

    try {
      // 获取年度总收支统计
      this.yearlyStatistics = await statisticsService.getStatistics(options);
      console.info(`${yearNum}年度统计数据: 收入${this.yearlyStatistics.totalIncome}, 支出${this.yearlyStatistics.totalExpense}`);

      // 获取年度分类统计
      this.yearlyStats = await statisticsService.getCategoryStatistics(this.currentStatType, options);

      // 递增触发器，强制UI更新
      this.statsUpdateTrigger++;
    } catch (error) {
      console.error(`加载年度统计数据失败: ${JSON.stringify(error)}`);
    }
  }

  // 加载月度统计数据
  async loadMonthlyStatistics(year: number, month: number) {
    console.info(`开始加载${year}年${month}月统计数据`);

    // 确保month和year是有效的数字
    const yearNum = Number(year);
    const monthNum = Number(month);

    if (isNaN(yearNum) || isNaN(monthNum)) {
      console.error('无效的年份或月份');
      return;
    }

    // 构造当月开始和结束日期
    const monthStr = String(monthNum).padStart(2, '0');
    const startDate = `${yearNum}-${monthStr}-01`;

    // 计算当月最后一天
    const lastDay = new Date(yearNum, monthNum, 0).getDate();
    const endDate = `${yearNum}-${monthStr}-${String(lastDay).padStart(2, '0')}`;

    const options: StatisticsOptions = {
      startDate: startDate,
      endDate: endDate
    };

    try {
      // 获取月度总收支统计
      this.statistics = await statisticsService.getStatistics(options);
      console.info(`${yearNum}年${monthNum}月统计数据: 收入${this.statistics.totalIncome}, 支出${this.statistics.totalExpense}`);

      // 获取月度分类统计
      this.categoryStats = await statisticsService.getCategoryStatistics(this.currentStatType, options);

      // 递增触发器，强制UI更新
      this.statsUpdateTrigger++;
    } catch (error) {
      console.error(`加载月度统计数据失败: ${JSON.stringify(error)}`);
    }
  }

  // 根据指定年月加载账单
  async loadBillsByMonth(year: number, month: number) {
    this.isLoading = true;
    try {
      // 确保month和year是有效的数字
      const yearNum = Number(year);
      const monthNum = Number(month);

      if (isNaN(yearNum) || isNaN(monthNum)) {
        console.error('无效的年份或月份');
        return;
      }

      // 构造当月开始和结束日期
      const monthStr = String(monthNum).padStart(2, '0');
      const startDate = `${yearNum}-${monthStr}-01`;

      // 计算当月最后一天
      const lastDay = new Date(yearNum, monthNum, 0).getDate();
      const endDate = `${yearNum}-${monthStr}-${String(lastDay).padStart(2, '0')}`;

      console.info(`加载${yearNum}年${monthNum}月账单：${startDate} 至 ${endDate}`);

      // 使用日期范围过滤指定月份账单
      this.bills = await billService.getBillsByOptions({
        startDate: startDate,
        endDate: endDate,
        sortBy: 'date',
        sortOrder: 'desc'
      });

      // 加载指定月份的统计数据
      this.statistics = await statisticsService.getStatistics({
        startDate: startDate,
        endDate: endDate
      });

      // 更新分类统计
      const dateRange: StatisticsOptions = { startDate, endDate };
      this.categoryStats = await statisticsService.getCategoryStatistics(this.currentStatType, dateRange);

      // 递增触发器，强制UI更新
      this.statsUpdateTrigger++;

      console.info(`加载到${this.bills.length}条${yearNum}年${monthNum}月账单记录`);
    } catch (error) {
      console.error(`加载账单失败: ${JSON.stringify(error)}`);
    } finally {
      this.isLoading = false;
    }
  }

  // 判断选择的月份是否是当前月份
  isCurrentMonth(): boolean {
    const now = new Date();
    const currentYear = now.getFullYear();
    const currentMonth = now.getMonth() + 1;

    return currentYear === this.selectedDate.getFullYear() &&
      currentMonth === this.selectedDate.getMonth() + 1;
  }

  build() {
    Column() {
      // 显示总收支
      Row() {
        Column() {
          Row() {
            Text(this.isCurrentMonth() ? '本月支出:' : `${this.selectedMonthString}支出:`).fontSize(18).margin({ left: 10, bottom: 10 })
            //月份选择器（日期选择挡掉"日"部分），文本显示当前月，显示本月支出，选择月份后显示x月支出，账单表更新为x月的账单
            DatePicker({
              start: new Date('1970-1-1'),
              end: new Date('2100-1-1'),
              selected: this.selectedDate
            })
              .position({x:220,y:-15})
              .selectedTextStyle({
                color:Color.Black,
                font:{size:15}
              })
              .textStyle({
                color:'#cdcdcd',
                font:{size:13}
              })
              .width(160)
              .height(140)
              .onDateChange((value: Date) => {
                this.selectedDate = value;
                // 设置年份和月份（月份从0开始计数）
                const year = value.getFullYear();
                const month = value.getMonth() + 1;
                this.selectedMonth = month;

                // 判断是否是当前月份,当前月份显示"本月"
                if (this.isCurrentMonth()) {
                  this.selectedMonthString = `本月`;
                } else {
                  this.selectedMonthString = `${year}年${month}月`;
                }

                this.loadBillsByMonth(year, month);
              })
            //用来挡掉日期选择器的"日"部分
            Column(){}.position({x:'97%',y:-15}).backgroundColor(Color.White).width(50).height(140).zIndex(2)
            //
          }
          Text(`￥${this.statistics.totalExpense.toFixed(2)}`)
            .fontSize(35)
            .fontWeight(FontWeight.Bold)
            .margin({bottom:10})
            .textAlign(TextAlign.Start)
            .fontColor('#f53f3f')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.MARQUEE })
            .width(200)

          Row() {
            Text('收入:  ')
              .margin({ left: 10 })
              .textAlign(TextAlign.Start)
            Text(`￥${this.statistics.totalIncome.toFixed(2)}`)
              .width(100)
              .fontWeight(600)
              .textOverflow({ overflow: TextOverflow.MARQUEE })
              .maxLines(1)
              .textAlign(TextAlign.Start)
              .fontColor('#07c160')
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .padding(10)
      }
      .width('100%')
      .padding(10)

      // 账单列表
      Column() {
        if (this.isLoading) {
          LoadingProgress()
            .width(50)
            .height(50)
            .color('#666')
        } else if (this.bills.length === 0) {
          Column() {
            Text('暂无账单记录').fontSize(16).margin({ top: 10 }).fontColor('#666')
          }
          .width('100%')
          .height('70%')
          .justifyContent(FlexAlign.Center)
        } else {
          List() {
            ForEach(this.bills, (bill: BillRecord) => {
              ListItem() {
                this.billItemBuilder(bill)
              }
            })
          }
          .width('100%')
          .layoutWeight(1)
          .padding({ left: 5, right: 5 })
        }
      }
      .margin({ top: 15 })
      .backgroundColor('#f5f5f5')
      .width('94%')
      .layoutWeight(1)
      .borderRadius(30)
      .padding({left:7,right:7,top:15})
    }
    .height('100%')
    .width('100%')
  }
}