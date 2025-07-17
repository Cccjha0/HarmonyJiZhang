import { billService, statisticsService } from '../common/AppServiceRegistry';
import { BillRecord, CategoryStatItem, StatisticsOptions, StatisticsResult } from '../common/models/Bill';
import { promptAction } from '@kit.ArkUI';

import { BillCell, BillDetail, WEEKS } from '../model/SourceDataModel';
import { CommonConstants } from '../constants/CommonConstants';

const FULL_YEAR = 12;

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
  @State calendarRefreshKey: number = 0;

  @State topRectHeight: number = AppStorage.get('topRectHeight') as number;
  @Prop year: number;
  @Prop month: number;
  @State selectedScopedMonth: string = '';
  private weeks: string[] = WEEKS;
  private today: Date = new Date();
  @State sourceData: BillRecord[] = [];
  @State flowCells: BillCell[] = [];
  @State private selectedDayFlow: BillCell = new BillCell(1, false, 0, 0, []);
  private prevCalendarRefreshKey: number = -1;

  async aboutToAppear() {
    // 初始化年份列表（近5年）
    const currentYear = new Date().getFullYear();
    this.yearList = Array.from<number, number>({ length: 5 }, (_, i) => currentYear - i);
    this.selectedYear = currentYear;

    this.today = new Date();

    // 使用统一加载逻辑，避免漏数据
    await this.updateSelectedMonth(this.today);
  }


  async getSourceData(): Promise<void> {
    this.sourceData = await billService.getBillsByMonth(this.year, this.month)
  }


  aboutToRender() {
    if (this.prevCalendarRefreshKey !== this.calendarRefreshKey) {
      this.prevCalendarRefreshKey = this.calendarRefreshKey;

      // 变化后执行刷新逻辑
      this.calcFlows(this.year, this.month, this.selectedDate.getDate());
    }
  }

  private parseDate(dateStr: string): Date {
    const parts = dateStr.split('-').map(Number)
    const year = parts[0]
    const month = parts[1]
    const day = parts[2]
    return new Date(year, month - 1, day)
  }

  // 日历图数据单元的初始化
  async calcFlows(y: number, m: number, day: number) {
    await this.getSourceData();
    this.selectedScopedMonth = this.year.toString() + '年' + this.month.toString() + '月'
    let thisFlows: BillCell[] = []
    const startDay = new Date(y, m - 1, 1)
    let daysOfThisMonth = new Date(y, m, 0).getDate()
    let startMissingDays = startDay.getDay() // 0~6，对应周日~周六
    // 补齐上个月的cells
    if (startMissingDays > 0) {
      let daysOfLastMonth = new Date(startDay.getFullYear(), startDay.getMonth(), 0).getDate()
      for (let i = daysOfLastMonth - startMissingDays + 1; i <= daysOfLastMonth; i++) {
        thisFlows.push(new BillCell(i, true, 0, 0, []))
      }
    }
    // 补上本月的cells
    for (let i = 1; i <= daysOfThisMonth; i++) {
      thisFlows.push(new BillCell(i, false, 0, 0, []))
    }
    // 往本月的cell中填充数据
    for (let i = 0; i < this.sourceData.length; i++) {
      let day = this.parseDate(this.sourceData[i].date).getDate();
      thisFlows[day + startMissingDays - 1].addDetails(this.sourceData[i])
    }
    // 如果选中月非当前月，则需补充下个月的前几天做填充
    let endMissingDays = 6 - new Date(y, m - 1, daysOfThisMonth).getDay()
    if (y !== this.today.getFullYear() || m !== this.today.getMonth() + 1) {
      for (let i = 1; i <= endMissingDays; i++) {
        thisFlows.push(new BillCell(i, true, 0, 0, []))
      }
    }
    // 给填充的日期单元格更换背样式
    for (let i = 0; i < thisFlows.length; i++) {
      if (thisFlows[i].isSupplemental) {
        thisFlows[i].changeCellStyle($r('app.color.background_color'), $r('app.color.supplemental_date_font_color'))
      }
    }
    this.flowCells = thisFlows
    // 设置默认展示的日期
    let showIndex = day + startMissingDays - 1
    this.selectedDayFlow = this.flowCells[showIndex]
    this.selectedDayFlow.changeCellStyle($r('app.color.selected_date_cell_background'),
      $r('app.color.selected_date_font_color'))
    this.selectedDate = new Date(y, m - 1, day)
    console.info(`生成 ${this.flowCells.length} 个 flowCell 单元格`)
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

  private async updateSelectedMonth(date: Date) {
    this.selectedDate = date
    this.year = date.getFullYear()
    this.month = date.getMonth() + 1

    await this.getSourceData()
    await this.calcFlows(this.year, this.month, date.getDate())
    await this.loadMonthlyStatistics(this.year, this.month)
    await this.loadBillsByMonth(this.year, this.month)

    this.selectedMonthString = this.isCurrentMonth() ? '本月' : `${this.year}年${this.month}月`
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
          .fontColor(bill.type === '支出' ? '#07c160' : '#f53f3f')
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
              .backgroundColor(this.currentStatType === '支出' ? '#07c160' : '#f53f3f')
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
        .fontColor(this.currentStatType === '支出' ? '#07c160' : '#f53f3f')
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
          }
          Text(`￥${this.statistics.totalExpense.toFixed(2)}`)
            .fontSize(35)
            .fontWeight(FontWeight.Bold)
            .margin({bottom:10})
            .textAlign(TextAlign.Start)
            .fontColor('#07c160')
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
              .fontColor('#f53f3f')
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .padding(10)
      }
      .width('100%')
      .padding(10)

      Column() {
        Row() {
          Text(this.selectedScopedMonth)
            .size({ width: $r('app.float.width_subtitle'), height: $r('app.float.height_subtitle') })
            .font({ size: $r('app.float.subtitle_font_size'), weight: CommonConstants.FONT_WEIGHT })
          Image($r('app.media.arrow_bottom'))
            .size({ width: $r('app.float.height_subtitle'), height: $r('app.float.height_subtitle') })
        }
        .size({ width: $r('app.float.width_half'), height: $r('app.float.height_subtitle') })
        .margin({ left: $r('app.float.selectedMonth_margin_left'), right: $r('app.float.selectedMonth_margin_right') })
        .onClick(() => {
          DatePickerDialog.show({
            start: new Date('2000-1-1'),
            end: this.today,
            selected: this.selectedDate,
            lunar: false,
            disappearTextStyle: { color: Color.Gray, font: { size: '14fp', weight: FontWeight.Normal } },
            textStyle: { color: Color.Black, font: { size: '18fp', weight: FontWeight.Regular } },
            selectedTextStyle: { color: Color.Black, font: { size: '22fp', weight: FontWeight.Bold } },
            acceptButtonStyle: { fontColor: $r('app.color.selected_date_cell_background') },
            cancelButtonStyle: { fontColor: Color.Gray },
            onDateAccept: (value: Date) => {
              this.selectedDate = value
              this.year = value.getFullYear()
              this.month = value.getMonth() + 1

              // 日历数据刷新
              this.calcFlows(this.year, this.month, value.getDate())

              // 顶部总收支刷新
              this.loadMonthlyStatistics(this.year, this.month)

              this.loadBillsByMonth(this.year, this.month)

              // 同步顶部“x月支出”文字
              const now = new Date()
              if (this.year === now.getFullYear() && this.month === now.getMonth() + 1) {
                this.selectedMonthString = '本月'
              } else {
                this.selectedMonthString = `${this.year}年${this.month}月`
              }
            }
          })
        })

        Row() {
          ForEach(this.weeks, (item: string) => {
            Text(item)
              .textAlign(TextAlign.Center)
              .size({ width: $r('app.float.calendar_item_size'), height: $r('app.float.calendar_item_size') })
              .font({ size: $r('app.float.font_size_usual') })
              .fontColor(Color.Gray)
          })
        }
        .size({ width: $r('app.float.width_max'), height: $r('app.float.height_weeks') })
        .margin({ left: $r('app.float.space_16'), right: $r('app.float.space_16') })
        .justifyContent(FlexAlign.SpaceBetween)

        Column() {
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(this.flowCells, (item: BillCell, index: number) => {
              Column() {
                Text(item.day.toString())
                  .size({ width: $r('app.float.calendar_item_size'), height: $r('app.float.calendar_item_size') })
                  .font({ size: $r('app.float.font_size_usual') })
                  .fontColor(item.cellFontColor)
                  .backgroundColor(item.cellColor)
                  .borderRadius($r('app.float.border_radius_24'))
                  .textAlign(TextAlign.Center)
                Text(item.income.toString())
                  .size({ width: $r('app.float.calendar_item_size'), height: $r('app.float.calendar_item_size_half') })
                  .font({ size: $r('app.float.income_font_size') })
                  .margin({ bottom: 2 })
                  .fontColor(Color.Red)
                  .textAlign(TextAlign.Center)
                  .visibility(item.income > 0 ? Visibility.Visible : Visibility.Hidden)
                Text(item.expense.toString())
                  .size({ width: $r('app.float.calendar_item_size'), height: $r('app.float.calendar_item_size_half') })
                  .font({ size: $r('app.float.income_font_size') })
                  .margin({ top: 2 })
                  .fontColor(Color.Green)
                  .textAlign(TextAlign.Center)
                  .visibility(item.expense > 0 ? Visibility.Visible : Visibility.Hidden)
              }
              .size({ width: $r('app.float.width_calendar_item'), height: $r('app.float.height_title') })
              .onClick(() => {
                if (!item.isSupplemental) {
                  // 先将之前选中单元格的样式换成通用样式
                  this.selectedDayFlow.changeCellStyle($r('app.color.scoped_date_cell_background'),
                    $r('app.color.scoped_date_font_color'))
                  // 将当前选中的单元格样式改为选中样式
                  item.changeCellStyle($r('app.color.selected_date_cell_background'),
                    $r('app.color.selected_date_font_color'))
                  this.selectedDayFlow = item
                  this.selectedDate = new Date(this.year, this.month - 1, item.day)
                  this.flowCells = [...this.flowCells]
                  return
                }
                // 需要执行月份切换
                if (index <= FULL_YEAR / 2) {
                  this.year = this.month === 1 ? this.year - 1 : this.year
                  this.month = this.month === 1 ? FULL_YEAR : this.month - 1
                } else {
                  this.year = this.month === FULL_YEAR ? this.year + 1 : this.year
                  this.month = this.month === FULL_YEAR ? 1 : this.month + 1
                }
                this.calcFlows(this.year, this.month, item.day)
              })
            })
          }.align(Alignment.Center)
        }.width($r('app.float.width_calendar'))

        Row() {
          Text($r('app.string.CapitalFlow'))
            .size({ width: $r('app.float.width_subtitle'), height: $r('app.float.height_subtitle') })
            .font({ size: $r('app.float.subtitle_font_size'), weight: CommonConstants.FONT_WEIGHT_SUBTITLE })
            .margin({ top: $r('app.float.space_12'), bottom: $r('app.float.space_12') })
            .textAlign(TextAlign.Start)
          Row() {
            Text($r('app.string.income'))
              .font({ size: $r('app.float.font_size_usual') })
              .fontColor(Color.Gray)
            Text(this.selectedDayFlow.income?.toString())
              .fontColor(Color.Red)
              .margin({ left: $r('app.float.space_5') })
            Text($r('app.string.expenses'))
              .font({ size: $r('app.float.font_size_usual') })
              .fontColor(Color.Gray)
              .margin({ left: $r('app.float.space_10') })
            Text(this.selectedDayFlow.expense?.toString())
              .fontColor(Color.Green)
              .margin({ left: $r('app.float.space_5') })
          }
          .layoutWeight(1)
          .margin({ top: $r('app.float.space_14'), bottom: $r('app.float.space_14') })
          .justifyContent(FlexAlign.End)
        }
        .size({ width: $r('app.float.width_max'), height: $r('app.float.height_subtitle2') })
        .margin({ left: $r('app.float.space_16'), right: $r('app.float.space_16') })

        Column() {
          ForEach(this.selectedDayFlow.flowDetails, (item: BillDetail, index: number) => {
            Row() {
              Image(item.icon)
                .size({ width: $r('app.float.icon_size'), height: $r('app.float.icon_size') })
                .margin({
                  left: $r('app.float.space_12'),
                  top: $r('app.float.space_20'),
                  bottom: $r('app.float.space_20')
                })
                .align(Alignment.Center)

              Column() {
                Text(item.title)
                  .height($r('app.float.height_flow_title'))
                  .fontWeight(CommonConstants.FONT_WEIGHT)
                Text(item.detail)
                  .height($r('app.float.height_flow_detail'))
                  .font({ size: $r('app.float.font_size_usual') })
                  .margin({ top: 2 })
              }
              .alignItems(HorizontalAlign.Start)
              .margin({ left: $r('app.float.space_16'), top: $r('app.float.space_12'), bottom: $r('app.float.space_12') })

              Column() {
                Text(item.amount.toString())
                  .font({ size: $r('app.float.font_size_usual') })
                  .fontColor(item.isIncome ? Color.Red : Color.Green)
                  .textAlign(TextAlign.End)
              }
              .alignItems(HorizontalAlign.End)
              .size({ width: $r('app.float.width_amount'), height: $r('app.float.height_amount') })
              .margin({ top: $r('app.float.space_12'), bottom: $r('app.float.space_12') })
            }
            .size({ width: $r('app.float.width_max'), height: $r('app.float.height_flow_item') })

            Divider()
              .width($r('app.float.width_divider'))
              .strokeWidth(0.5)
              .margin({ left: $r('app.float.divider_margin_left'), right: $r('app.float.space_12') })
              .color(index === this.selectedDayFlow.flowDetails.length - 1 ? Color.White : Color.Gray)
          })
        }
        .width($r('app.float.width_max'))
        .margin({ left: $r('app.float.space_16'), right: $r('app.float.space_16') })
        .borderRadius($r('app.float.border_radius_12'))
        .backgroundColor(Color.White)
        .visibility(this.selectedDayFlow.flowDetails.length > 0 ? Visibility.Visible : Visibility.Hidden)

        Column() {
          Text($r('app.string.Not_available'))
        }
        .size({ width: $r('app.float.width_max'), height: $r('app.float.height_flow_item') })
        .margin({ left: $r('app.float.space_16'), right: $r('app.float.space_16') })
        .borderRadius($r('app.float.border_radius_12'))
        .backgroundColor(Color.White)
        .justifyContent(FlexAlign.Center)
        .visibility(this.selectedDayFlow.flowDetails.length > 0 ? Visibility.Hidden : Visibility.Visible)

      }
      .height('100%')
      .width('100%')
      .backgroundColor($r('app.color.background_color'))
      .padding({
        left: $r('app.float.space_16'), right: $r('app.float.space_16'),
        top: px2vp(this.topRectHeight)
      })
    }

    .height('100%')
    .width('100%')
  }
}