/*
 * Copyright (c) 2025 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import { BillCell, BillDetail, SOURCE_DATA, SourceData, WEEKS } from '../model/SourceDataModel';
import { CommonConstants } from '../constants/CommonConstants';

const FULL_YEAR = 12;

@Entry
@Component
struct FlowCalendar {
  @State topRectHeight: number = AppStorage.get('topRectHeight') as number;
  @State year: number = 2025;
  @State month: number = 5;
  @State selectedScopedMonth: string = '';
  private weeks: string[] = WEEKS;
  private today: Date = new Date();
  @State sourceData: SourceData[] = [];
  @State flowCells: BillCell[] = [];
  @State private selectedDayFlow: BillCell = new BillCell(1, false, 0, 0, []);
  @State private selectedDate: Date = this.today;


  aboutToAppear(): void {
    this.sourceData = SOURCE_DATA
    this.today = new Date()
    this.year = this.today.getFullYear()
    this.month = this.today.getMonth() + 1
    this.calcFlows(this.year, this.month, this.today.getDate())
  }

  // 日历图数据单元的初始化
  calcFlows(y: number, m: number, day: number) {
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
      let day = this.sourceData[i].payDate.getDate()
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
  }

  build() {
    Column() {
      // Row() {
      //   Text(this.selectedScopedMonth)
      //     .size({ width: $r('app.float.width_subtitle'), height: $r('app.float.height_subtitle') })
      //     .font({ size: $r('app.float.subtitle_font_size'), weight: CommonConstants.FONT_WEIGHT })
      //   Image($r('app.media.arrow_bottom'))
      //     .size({ width: $r('app.float.height_subtitle'), height: $r('app.float.height_subtitle') })
      // }
      // .size({ width: $r('app.float.width_half'), height: $r('app.float.height_subtitle') })
      // .margin({ left: $r('app.float.selectedMonth_margin_left'), right: $r('app.float.selectedMonth_margin_right') })
      // .onClick(() => {
      //   DatePickerDialog.show({
      //     start: new Date('2000-1-1'),
      //     end: this.today,
      //     selected: this.selectedDate,
      //     lunar: false,
      //     disappearTextStyle: { color: Color.Gray, font: { size: '14fp', weight: FontWeight.Normal } },
      //     textStyle: { color: Color.Black, font: { size: '18fp', weight: FontWeight.Regular } },
      //     selectedTextStyle: { color: Color.Black, font: { size: '22fp', weight: FontWeight.Bold } },
      //     acceptButtonStyle: { fontColor: $r('app.color.selected_date_cell_background') },
      //     cancelButtonStyle: { fontColor: Color.Gray },
      //     onDateAccept: (value: Date) => {
      //       this.selectedDate = value
      //       this.year = value.getFullYear()
      //       this.month = value.getMonth() + 1
      //       this.calcFlows(this.year, this.month, value.getDate())
      //     }
      //   })
      // })

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
}

export { FlowCalendar };
