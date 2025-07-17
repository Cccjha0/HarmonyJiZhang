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

import { BillRecord } from '../common/models/Bill'
import { AccountRecord } from '../common/models/Account'
import { billService, accountService } from '../common/AppServiceRegistry';

// Bill {
//   id:
//   date: string;
//   type: '收入' | '支出';
//   category: string;
//   amount: number;
//   remark?: string;
//   accountId: number;
// }

// export class SourceData {
//   isIncome: boolean = false
//   title: string = ''
//   amount: number = 0.0
//   paymentMethod: string = '现金'
//   account: string = ''
//   payDate: Date = new Date()
//   icon: Resource = $r('app.media.heart')
//
//   constructor(isIncome: boolean, title: string, amount: number, paymentMethod: string, account: string, payDate: Date,
//     icon: Resource) {
//     this.isIncome = isIncome
//     this.title = title
//     this.amount = amount
//     this.paymentMethod = paymentMethod
//     this.account = account
//     this.payDate = payDate
//     this.icon = icon
//   }
// }

const CATEGORY_ICON_MAP: Record<string, Resource> = {
  '餐饮': $r('app.media.cy'),
  '医疗': $r('app.media.yl'),
  '交通': $r('app.media.jt'),
  '住房': $r('app.media.zf'),
  '零食烟酒': $r('app.media.lsyj'),
  '学习': $r('app.media.xx'),
  '通讯': $r('app.media.tx'),
  '社交': $r('app.media.sj'),
  '投资': $r('app.media.tz'),
  '购物': $r('app.media.gw'),
  '娱乐': $r('app.media.yule'),
  '外借': $r('app.media.zz'),
  '其他': $r('app.media.other'),
  '工资': $r('app.media.gz'),
  '奖金': $r('app.media.jj'),
  '租金': $r('app.media.zj'),
  '报销': $r('app.media.bx'),
  '退款': $r('app.media.tk'),
  '红包': $r('app.media.hb'),
  '利息': $r('app.media.lx'),
  '交易': $r('app.media.jy'),
  '奖学金': $r('app.media.jxj'),
  '分红': $r('app.media.fh'),
};

export class BillDetail {
  isIncome: boolean = false
  title: string = ''
  amount: number = 0.0
  detail: string = ''
  icon: Resource = $r('app.media.heart')

  constructor(isIncome: boolean, title: string, amount: number, detail: string, icon: Resource) {
    this.isIncome = isIncome
    this.title = title
    this.amount = amount
    this.detail = detail
    this.icon = icon
  }
}


export class BillCell {
  day: number = 1
  isSupplemental: boolean = false
  income: number = 0
  expense: number = 0
  cellColor: Resource = $r('app.color.scoped_date_cell_background')
  cellFontColor: Resource = $r('app.color.scoped_date_font_color')
  flowDetails: Array<BillDetail> = []

  constructor(day: number, isSupplemental: boolean, income: number, expense: number, flowDetails: Array<BillDetail>) {
    this.day = day
    this.isSupplemental = isSupplemental
    this.income = income
    this.expense = expense
    this.flowDetails = flowDetails
  }

  addDetails(billRecord: BillRecord) {
    let iconRes: Resource = CATEGORY_ICON_MAP[billRecord.category] ?? $r('app.media.default_icon');

    if (billRecord.type == '收入') {
      this.income += billRecord.amount
    } else {
      this.expense += billRecord.amount
    }
    let detail = accountService.getAccountById(billRecord.accountId) + ' ' + billRecord.date
    this.flowDetails.push(
      new BillDetail(billRecord.type == '收入', billRecord.category, billRecord.amount, detail, iconRes))
  }

  changeCellStyle(cellColor: Resource, cellFontColor: Resource) {
    this.cellColor = cellColor
    this.cellFontColor = cellFontColor
  }
}

// 原始数据
// export const SOURCE_DATA: Array<SourceData> = [
//   new SourceData(false, '慈善捐助', 10.0, '现金', '159****1700', new Date(2025, 5, 12, 9, 24), $r('app.media.heart')),
//   new SourceData(false, '晚餐', 24.3, '现金', '159****1700', new Date(2025, 5, 12, 18, 23), $r('app.media.knives')),
//   new SourceData(true, '工资', 3000.0, '现金', '159****1700', new Date(2025, 5, 15, 15, 39), $r('app.media.heart')),
//   new SourceData(false, '午餐', 56.8, '现金', '159****1700', new Date(2025, 5, 15, 11, 39), $r('app.media.knives')),
//   new SourceData(true, '退款', 123.0, '现金', '159****1700', new Date(2025, 5, 25, 10, 35), $r('app.media.heart')),
//   new SourceData(false, '晚餐', 56.8, '现金', '159****1700', new Date(2025, 5, 25, 17, 59), $r('app.media.knives'))
// ]

export const WEEKS: string[] = ['日', '一', '二', '三', '四', '五', '六']
