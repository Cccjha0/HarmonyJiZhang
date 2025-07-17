import { billService, statisticsService } from '../common/AppServiceRegistry';
import { BillRecord, CategoryStatItem, StatisticsOptions, StatisticsResult } from '../common/models/Bill';
import { promptAction } from '@kit.ArkUI';
import { McPieChart, Options } from '@mcui/mccharts'

interface ChartItem {
  name: string;
  value: number;
}

@Entry
@Component
export default struct StatisticsPage{

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


  @State chartData: ChartItem[] = [];

  @State defOptions: Options = new Options({
    //调色盘颜色列表
    color: ['#caceb5', '#bbaab8', '#6f9f9c', '#e2d8af',
      '#929b80', '#95bccc', '#afac9b', '#697a98',
      '#676966', '#e1a36f', '#88845f', '#84a59d',
      '#ff059cca'],
    //设置图例的相关样式与功能
    legend: {
      top: '1%', //图例距离顶部侧位置
      itemWidth: 10, //图形的宽度
      itemHeight: 10, //图形的高度
      textStyle: {
        //文本样式配置
        color: '#ff029cdd', //字体颜色
        fontSize: 30, //字体大小
        fontWeight: '800' //字体粗细
      }
    },
    title: {
      show: true,
      text: this.currentStatType+'数据占比', // 主标题文本
      subtext: '', // 副标题文本
      top: '30%',
      fontSize: 20, //字体大小
    },
    series: [
      {
        radius: ['50%', '35%'], // 饼图外半径、内半径
        center: ['50%', '75%'], // 饼图中心位置
        data: this.chartData,
        labelLine: {
          //文本连接线样式配置
          length: 25, //连接线1的长度
          length2: 30, //连接线2的长度
          lineStyle: {
            //提示线样式
            width: 1, //线宽度
            color: '#effffb' //线颜色
          }
        },
        label: {
          //系列文本标签样式配置
          show: true, //是否显示文本标签
          fontWeight: '800', //字体粗细
          fontFamily: 'sans-serif',
          color: '#ffffffff', //字体颜色
          position: 'outside', //文本显示位置
          fontSize: 30, //字体大小
          distanceToLabelLine: 6 //字体与饼状间距
        },
      }
    ],

  })

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
    //清空残留数据
    this.categoryStats = [];
    this.chartData = [];
    // 更新月度统计数据
    this.categoryStats = await statisticsService.getCategoryStatistics(type, dateRange);

    this.chartData = this.categoryStats.map((item: CategoryStatItem) => {
      return {
        name: item.category,
        value: item.total
      } as ChartItem;
    });

    this.defOptions = new Options({
      //调色盘颜色列表
      color: ['#caceb5', '#bbaab8', '#e1a36f', '#e2d8af',
        '#929b80', '#95bccc', '#afac9b', '#697a98',
        '#676966', '#6f9f9c', '#88845f', '#84a59d',
        '#ff059cca'],
      //设置图例的相关样式与功能
      legend: {
        top: '3%', //图例距离顶部侧位置
        itemWidth: 10, //图形的宽度
        itemHeight: 10, //图形的高度
        textStyle: {
          //文本样式配置
          color: '#233c4b', //字体颜色
          fontSize: 30, //字体大小
          fontWeight: '800' //字体粗细
        }
      },
      title: {
        show: true,
        text: this.currentStatType+'数据占比', // 主标题文本
        subtext: '', // 副标题文本
        top: '30%',
        fontSize: 20, //字体大小
      },
      series: [
        {
          radius: ['50%', '35%'], // 饼图外半径、内半径
          center: ['50%', '32%'], // 饼图中心位置
          data: this.chartData,
          labelLine: {
            //文本连接线样式配置
            length: 25, //连接线1的长度
            length2: 30, //连接线2的长度
            lineStyle: {
              //提示线样式
              width: 1, //线宽度
              color: '#effffb' //线颜色
            }
          },
          label: {
            //系列文本标签样式配置
            show: true, //是否显示文本标签
            fontWeight: '800', //字体粗细
            fontFamily: 'sans-serif',
            color: '#ffffffff', //字体颜色
            position: 'outside', //文本显示位置
            fontSize: 30, //字体大小
            distanceToLabelLine: 6 //字体与饼状间距
          },
        }
      ],
    });


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
      //刷新
      await this.loadCategoryStats(this.currentStatType, options);

      // 递增触发器，强制UI更新
      this.statsUpdateTrigger++;
    } catch (error) {
      console.error(`加载年度统计数据失败: ${JSON.stringify(error)}`);
    }
  }

  // 加载月度统计数据
  async loadMonthlyStatistics(year: number, month: number) {
    console.info(`开始加载${year}年${month}月统计数据`);
    //清空数据
    this.categoryStats = [];
    this.chartData = [];

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
      //this.categoryStats = await statisticsService.getCategoryStatistics(this.currentStatType, options);

      await this.loadCategoryStats(this.currentStatType, options);

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
      // 标题和日月切换按钮
      Row() {
        Text('收支统计').fontSize(20).fontWeight(FontWeight.Bold)

        // 根据当前标签页显示不同的选择器
        if (this.statsTabIndex === 0) {
          // 月份选择器
          Select(this.monthList.map(month => ({ value: month } as SelectOption)))
            .selected(this.statsSelectedMonth - 1)  // 月份索引从0开始，所以需要减1
            .value(this.monthList[this.statsSelectedMonth - 1])
            .font({ size: 16 })
            .fontColor('#333')
            .onSelect((index: number): void => {
              this.statsSelectedMonth = index + 1;  // 月份从1开始，所以需要加1
              this.loadMonthlyStatistics(this.selectedYear, this.statsSelectedMonth);
            })
        } else {
          // 年份选择器
          Select(this.yearList.map(year => ({ value: year.toString() } as SelectOption)))
            .selected(this.yearList.findIndex(year => year === this.selectedYear) || 0)
            .value(this.selectedYear.toString())
            .font({ size: 16 })
            .fontColor('#333')
            .onSelect((index: number): void => {
              this.selectedYear = this.yearList[index];
              this.loadYearlyStatistics(this.selectedYear);
            })
        }

        Row() {
          Button('支出')
            .fontSize(14)
            .backgroundColor(this.currentStatType === '支出' ? '#333' : '#e0e0e0')
            .fontColor(this.currentStatType === '支出' ? Color.White : '#333')
            .margin({ right: 5 })
            .height(28)
            .onClick((): void => {
              this.loadCategoryStats('支出');
              if (this.statsTabIndex === 1) {
                // 只有在年度页才加载年度统计
                this.loadYearlyStatistics(this.selectedYear);
              } else {
                // 月度页刷新当前月度数据
                this.loadMonthlyStatistics(this.selectedYear, this.statsSelectedMonth);
              }
            })

          Button('收入')
            .fontSize(14)
            .backgroundColor(this.currentStatType === '收入' ? '#333' : '#e0e0e0')
            .fontColor(this.currentStatType === '收入' ? Color.White : '#333')
            .height(28)
            .onClick((): void => {
              this.loadCategoryStats('收入');
              if (this.statsTabIndex === 1) {
                // 只有在年度页才加载年度统计
                this.loadYearlyStatistics(this.selectedYear);
              } else {
                // 月度页刷新当前月度数据
                this.loadMonthlyStatistics(this.selectedYear, this.statsSelectedMonth);
              }
            })
        }
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .padding({left: 15, right: 15, top: 15, bottom: 10})

      // 切换月度/年度统计
      Tabs() {
        // 月度统计标签页
        TabContent() {
          Column() {

            // 总收支显示
            Row() {
              Column() {
                Text(`${this.statsSelectedMonth}月支出`).fontSize(14).fontColor('#666')
                Text(`￥${this.statistics.totalExpense.toFixed(2)}`)
                  .fontSize(24)
                  .fontColor('#07c160')
                  .textOverflow({ overflow: TextOverflow.MARQUEE })
              }
              .width('50%')
              .alignItems(HorizontalAlign.Center)

              Column() {
                Text(`${this.statsSelectedMonth}月收入`).fontSize(14).fontColor('#666')
                Text(`￥${this.statistics.totalIncome.toFixed(2)}`)
                  .fontSize(24)
                  .fontColor('#f53f3f')
                  .textOverflow({ overflow: TextOverflow.MARQUEE })
              }
              .width('50%')
              .alignItems(HorizontalAlign.Center)
            }
            .padding(15)
            .margin({ bottom: 10 })
            .backgroundColor(Color.White)
            .borderRadius(15)
            //图表

            Column() {
              //饼状图组件
              McPieChart({ options: this.defOptions })
                .height('170%') //设置图表区域的高度
            }
            .height('35%')
            .width('100%')

            // 分类统计图表
            Column() {
              Text(`${this.statsSelectedMonth}月${this.currentStatType}分类统计`)
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .width('100%')
                .textAlign(TextAlign.Start)
                .margin({ bottom: 15 })

              if (this.categoryStats.length === 0) {
                Column() {
                  Text(`暂无${this.currentStatType}记录`).fontSize(14).fontColor('#666')
                }
                .width('100%')
                .height(200)
                .justifyContent(FlexAlign.Center)
              } else {
                List() {
                  ForEach(this.categoryStats, (item: CategoryStatItem, index: number) => {
                    ListItem() {
                      this.categoryStatItem(
                        item,
                        this.currentStatType === '支出' ? this.statistics.totalExpense : this.statistics.totalIncome
                      )
                    }
                    .key(`${item.category}-${this.statsUpdateTrigger}-${index}`)
                  })
                }
                .width('100%')
              }
            }
            .width('100%')
            .backgroundColor(Color.White)
            .borderRadius(15)
            .padding(15)
            .layoutWeight(1)
          }
          .padding(15)
          .height('100%')
        }
        .tabBar('月度统计')


        // 年度统计标签页
        TabContent() {
          Column() {
            // 年度总收支显示
            Row() {
              Column() {
                Text(`${this.selectedYear}年支出`).fontSize(14).fontColor('#666')
                Text(`￥${this.yearlyStatistics.totalExpense.toFixed(2)}`).fontSize(24).fontColor('#07c160')
                  .textOverflow({ overflow: TextOverflow.MARQUEE })
              }
              .width('50%')
              .alignItems(HorizontalAlign.Center)

              Column() {
                Text(`${this.selectedYear}年收入`).fontSize(14).fontColor('#666')
                Text(`￥${this.yearlyStatistics.totalIncome.toFixed(2)}`).fontSize(24).fontColor('#f53f3f')
                  .textOverflow({ overflow: TextOverflow.MARQUEE })
              }
              .width('50%')
              .alignItems(HorizontalAlign.Center)
            }
            .padding(15)
            .margin({ bottom: 10 })
            .backgroundColor(Color.White)
            .borderRadius(15)
            //图表

            Column() {
              //饼状图组件
              McPieChart({ options: this.defOptions })
                .height('170%') //设置图表区域的高度
            }
            .height('35%')
            .width('100%')

            // 年度分类统计图表
            Column() {
              Text(`${this.selectedYear}年${this.currentStatType}分类统计`)
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .width('100%')
                .textAlign(TextAlign.Start)
                .margin({ bottom: 15 })

              if (this.yearlyStats.length === 0) {
                Column() {
                  Text(`${this.selectedYear}年暂无${this.currentStatType}记录`).fontSize(14).fontColor('#666')
                }
                .width('100%')
                .height(200)
                .justifyContent(FlexAlign.Center)
              } else {
                List() {
                  ForEach(this.yearlyStats, (item: CategoryStatItem, index: number) => {
                    ListItem() {
                      this.categoryStatItem(
                        item,
                        this.currentStatType === '支出' ? this.yearlyStatistics.totalExpense : this.yearlyStatistics.totalIncome
                      )
                    }
                    .key(`yearly-${item.category}-${this.statsUpdateTrigger}-${index}`)
                  })
                }
                .width('100%')
              }
            }
            .width('100%')
            .backgroundColor(Color.White)
            .borderRadius(15)
            .padding(15)
            .layoutWeight(1)
          }
          .padding(15)
          .height('100%')
        }
        .tabBar('年度统计')
      }
      .barMode(BarMode.Fixed)
      .barWidth('100%')
      .barHeight(50)
      .layoutWeight(1)
      .onChange((index: number) => {
        // 更新当前标签页索引
        this.statsTabIndex = index;

        if (index === 0) {
          // 切换到月度统计
          this.loadMonthlyStatistics(this.selectedYear, this.statsSelectedMonth);
        } else if (index === 1) {
          // 切换到年度统计
          this.loadYearlyStatistics(this.selectedYear);
        }
      })
    }
    .height('100%')
    .width('100%')
  }
}