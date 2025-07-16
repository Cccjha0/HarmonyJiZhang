export interface Bill {
  date: string;
  type: '收入' | '支出';
  category: string;
  amount: number;
  remark?: string;
}

export interface BillRecord extends Bill {
  id: number;
}

export interface QueryBillOptions {
  type?: '收入' | '支出';
  startDate?: string;
  endDate?: string;
  sortBy?: 'date' | 'amount';
  sortOrder?: 'asc' | 'desc';
}

export interface StatisticsOptions {
  startDate?: string;
  endDate?: string;
}

export interface CategoryStatItem {
  category: string;
  total: number;
}

export interface StatisticsResult {
  totalIncome: number;
  totalExpense: number;
}
