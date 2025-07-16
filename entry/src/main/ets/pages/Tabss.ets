import { promptAction, router } from "@kit.ArkUI";
import Statistics from '../pages/StatisticsPage';
import Home from '../pages/HomePage';
import { BillRecord, CategoryStatItem, StatisticsOptions, StatisticsResult } from "../common/models/Bill";
import { billService, statisticsService } from "../common/AppServiceRegistry";

@Entry
@Component
export default struct Tabss {

  @State currentIndex: number = 0;
  @State statsTabIndex: number = 0;
  @State selectedYear: number = new Date().getFullYear();
  @State selectedMonth: number = new Date().getMonth() + 1;
  @State yearList: number[] = [];
  @State statsSelectedMonth: number = new Date().getMonth() + 1;
  @State selectedDate: Date = new Date();
  @State selectedMonthString: string = "本月"; // 初始显示为"本月"
  @State isLoading: boolean = true;
  @State bills: BillRecord[] = [];
  @State statistics: StatisticsResult = { totalIncome: 0, totalExpense: 0 };
  @State currentStatType: '收入' | '支出' = '支出';
  @State categoryStats: CategoryStatItem[] = [];
  @State yearlyStats: CategoryStatItem[] = [];
  @State statsUpdateTrigger: number = 0;
  @State yearlyStatistics: StatisticsResult = { totalIncome: 0, totalExpense: 0 };
  @State hasInit: boolean = false;

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
      // 主界面中间加号按钮
      Image($r('app.media.add'))
        .width(60)
        .height(60)
        .position({
          x: '42%',
          y: '90%'
        })
        .zIndex(1)
        .onClick((): void => {
          router.pushUrl({
            url: "pages/AddAccounting"
          });
        })

      Tabs() {
        //   首页
        TabContent() {
          Home({
            currentIndex: this.currentIndex,
            statsTabIndex: this.statsTabIndex,
            selectedYear: this.selectedYear,
            selectedMonth: this.selectedMonth,
            yearList: this.yearList,
            statsSelectedMonth: this.statsSelectedMonth,
            selectedDate: this.selectedDate,
            selectedMonthString: this.selectedMonthString,
            isLoading: this.isLoading,
            bills: this.bills,
            statistics: this.statistics,
            currentStatType: this.currentStatType,
            categoryStats: this.categoryStats,
            yearlyStats: this.yearlyStats,
            statsUpdateTrigger: this.statsUpdateTrigger,
            yearlyStatistics: this.yearlyStatistics
          }
          );
        }.tabBar({icon:'',text:"首页"})
        //课程
        TabContent(){
          Statistics({
            currentIndex: this.currentIndex,
            statsTabIndex: this.statsTabIndex,
            selectedYear: this.selectedYear,
            selectedMonth: this.selectedMonth,
            yearList: this.yearList,
            statsSelectedMonth: this.statsSelectedMonth,
            selectedDate: this.selectedDate,
            selectedMonthString: this.selectedMonthString,
            isLoading: this.isLoading,
            bills: this.bills,
            statistics: this.statistics,
            currentStatType: this.currentStatType,
            categoryStats: this.categoryStats,
            yearlyStats: this.yearlyStats,
            statsUpdateTrigger: this.statsUpdateTrigger,
            yearlyStatistics: this.yearlyStatistics
          }

          );
        }.tabBar({icon:"",text:"统计"})
        //曲谱
        //TabContent(){
        //  Qupu();
        //}.tabBar({icon:"",text:"曲谱"})
        //关开
        //TabContent(){
        //  About();
        //}.tabBar({icon:"",text:"关于"})
      }.onChange((index: number): void => {
        this.currentIndex = index;
        // 当切换到统计页时，刷新统计数据
        if (index === 1) {
          // 设置初始标签为月度统计
          this.statsTabIndex = 0;

          // 加载年度统计数据
          this.loadYearlyStatistics(this.selectedYear);

          // 加载月度统计数据
          this.loadMonthlyStatistics(this.selectedYear, this.statsSelectedMonth);
        }
      })
      .width('100%')
      .height('100%')
      .barPosition(BarPosition.End)

    }
}
}