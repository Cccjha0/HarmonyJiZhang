import { Bill, BillRecord, QueryBillOptions } from '../models/Bill';
import relationalStore from '@ohos.data.relationalStore';
import { BusinessError } from '@kit.BasicServicesKit';

export class BillService {
  private rdbStore: relationalStore.RdbStore;
  private readonly tableName: string = 'BILL';

  constructor(rdbStore: relationalStore.RdbStore) {
    this.rdbStore = rdbStore;
  }

  /**
   * 添加账单
   * @param bill 账单数据
   * @returns Promise<number> 插入记录的ID，失败返回-1
   */
  async addBill(bill: Bill): Promise<number> {
    if (!this.rdbStore) {
      console.error('数据库未初始化');
      return -1;
    }

    const valuesBucket: relationalStore.ValuesBucket = {
      DATE: bill.date,
      TYPE: bill.type,
      CATEGORY: bill.category,
      AMOUNT: bill.amount,
      REMARK: bill.remark || '',
      ACCOUNT_ID: bill.accountId
    };

    try {
      const rowId = await this.rdbStore.insert(this.tableName, valuesBucket);
      console.info(`添加账单成功，ID: ${rowId}`);
      return rowId;
    } catch (err) {
      const error = err as BusinessError;
      console.error(`添加账单失败: ${error.message}`);
      return -1;
    }
  }

  /**
   * 删除账单
   * @param id 账单ID
   * @returns Promise<boolean> 是否删除成功
   */
  async deleteBill(id: number): Promise<boolean> {
    if (!this.rdbStore) {
      console.error('数据库未初始化');
      return false;
    }

    const predicates = new relationalStore.RdbPredicates(this.tableName);
    predicates.equalTo('BILL_ID', id);

    try {
      const deletedRows = await this.rdbStore.delete(predicates);
      console.info(`删除账单成功，影响行数: ${deletedRows}`);
      return deletedRows > 0;
    } catch (err) {
      const error = err as BusinessError;
      console.error(`删除账单失败: ${error.message}`);
      return false;
    }
  }

  /**
   * 更新账单
   * @param id 账单ID
   * @param bill 更新的账单数据
   * @returns Promise<boolean> 是否更新成功
   */
  async updateBill(id: number, bill: Partial<Bill>): Promise<boolean> {
    if (!this.rdbStore) {
      console.error('数据库未初始化');
      return false;
    }

    const valuesBucket: relationalStore.ValuesBucket = {};

    if (bill.date !== undefined) valuesBucket.DATE = bill.date;
    if (bill.type !== undefined) valuesBucket.TYPE = bill.type;
    if (bill.category !== undefined) valuesBucket.CATEGORY = bill.category;
    if (bill.amount !== undefined) valuesBucket.AMOUNT = bill.amount;
    if (bill.remark !== undefined) valuesBucket.REMARK = bill.remark;
    if (bill.accountId !== undefined) valuesBucket.ACCOUNT_ID = bill.accountId;

    const predicates = new relationalStore.RdbPredicates(this.tableName);
    predicates.equalTo('BILL_ID', id);

    try {
      const updatedRows = await this.rdbStore.update(valuesBucket, predicates);
      console.info(`更新账单成功，影响行数: ${updatedRows}`);
      return updatedRows > 0;
    } catch (err) {
      const error = err as BusinessError;
      console.error(`更新账单失败: ${error.message}`);
      return false;
    }
  }

  /**
   * 根据ID查询账单
   * @param id 账单ID
   * @returns Promise<BillRecord | null> 查询到的账单
   */
  async getBillById(id: number): Promise<BillRecord | null> {
    if (!this.rdbStore) {
      console.error('数据库未初始化');
      return null;
    }

    const predicates = new relationalStore.RdbPredicates(this.tableName);
    predicates.equalTo('BILL_ID', id);

    try {
      const resultSet = await this.rdbStore.query(predicates, ['BILL_ID', 'DATE', 'TYPE', 'CATEGORY', 'AMOUNT', 'REMARK','ACCOUNT_ID']);
      if (resultSet.rowCount <= 0) {
        resultSet.close();
        return null;
      }

      resultSet.goToFirstRow();
      const bill: BillRecord = {
        id: resultSet.getDouble(resultSet.getColumnIndex('BILL_ID')),
        date: resultSet.getString(resultSet.getColumnIndex('DATE')),
        type: resultSet.getString(resultSet.getColumnIndex('TYPE')) as '收入' | '支出',
        category: resultSet.getString(resultSet.getColumnIndex('CATEGORY')),
        amount: resultSet.getDouble(resultSet.getColumnIndex('AMOUNT')),
        remark: resultSet.getString(resultSet.getColumnIndex('REMARK')),
        accountId: resultSet.getDouble(resultSet.getColumnIndex('ACCOUNT_ID'))
      };

      resultSet.close();
      return bill;
    } catch (err) {
      const error = err as BusinessError;
      console.error(`查询账单失败: ${error.message}`);
      return null;
    }
  }

  /**
   * 获取全部账单（无任何查询条件）
   */
  async getAllBills(): Promise<BillRecord[]> {
    if (!this.rdbStore) {
      console.error('数据库未初始化');
      return [];
    }

    const predicates = new relationalStore.RdbPredicates(this.tableName);
    predicates.orderByDesc('DATE'); // 默认按日期降序排序

    try {
      const resultSet = await this.rdbStore.query(
        predicates,
        ['BILL_ID', 'DATE', 'TYPE', 'CATEGORY', 'AMOUNT', 'REMARK', 'ACCOUNT_ID']
      );

      const bills: BillRecord[] = [];

      while (resultSet.goToNextRow()) {
        bills.push({
          id: resultSet.getDouble(resultSet.getColumnIndex('BILL_ID')),
          date: resultSet.getString(resultSet.getColumnIndex('DATE')),
          type: resultSet.getString(resultSet.getColumnIndex('TYPE')) as '收入' | '支出',
          category: resultSet.getString(resultSet.getColumnIndex('CATEGORY')),
          amount: resultSet.getDouble(resultSet.getColumnIndex('AMOUNT')),
          remark: resultSet.getString(resultSet.getColumnIndex('REMARK')),
          accountId: resultSet.getDouble(resultSet.getColumnIndex('ACCOUNT_ID'))
        });
      }

      resultSet.close();
      return bills;
    } catch (err) {
      const error = err as BusinessError;
      console.error(`查询全部账单失败: ${error.message}`);
      return [];
    }
  }

  /**
   * 根据查询条件筛选账单
   * @param options 查询参数（账户、类型、起止日期、排序）
   */
  async getBillsByOptions(options: QueryBillOptions): Promise<BillRecord[]> {
    if (!this.rdbStore) {
      console.error('数据库未初始化');
      return [];
    }

    const predicates = new relationalStore.RdbPredicates(this.tableName);

    // 查询条件
    if (options?.accountId) {
      predicates.equalTo('ACCOUNT_ID', options.accountId);
    }
    if (options?.type) {
      predicates.equalTo('TYPE', options.type);
    }
    if (options?.startDate) {
      predicates.greaterThanOrEqualTo('DATE', options.startDate);
    }
    if (options?.endDate) {
      predicates.lessThanOrEqualTo('DATE', options.endDate);
    }

    // 排序
    if (options?.sortBy) {
      const field = options.sortBy === 'date' ? 'DATE' : 'AMOUNT';
      if (options.sortOrder === 'desc') {
        predicates.orderByDesc(field);
      } else {
        predicates.orderByAsc(field);
      }
    } else {
      predicates.orderByDesc('DATE');
    }

    try {
      const resultSet = await this.rdbStore.query(
        predicates,
        ['BILL_ID', 'DATE', 'TYPE', 'CATEGORY', 'AMOUNT', 'REMARK', 'ACCOUNT_ID']
      );

      const bills: BillRecord[] = [];

      while (resultSet.goToNextRow()) {
        bills.push({
          id: resultSet.getDouble(resultSet.getColumnIndex('BILL_ID')),
          date: resultSet.getString(resultSet.getColumnIndex('DATE')),
          type: resultSet.getString(resultSet.getColumnIndex('TYPE')) as '收入' | '支出',
          category: resultSet.getString(resultSet.getColumnIndex('CATEGORY')),
          amount: resultSet.getDouble(resultSet.getColumnIndex('AMOUNT')),
          remark: resultSet.getString(resultSet.getColumnIndex('REMARK')),
          accountId: resultSet.getDouble(resultSet.getColumnIndex('ACCOUNT_ID'))
        });
      }

      resultSet.close();
      return bills;
    } catch (err) {
      const error = err as BusinessError;
      console.error(`条件查询账单失败: ${error.message}`);
      return [];
    }
  }

  /**
   * 查询指定年月的账单
   * @param year 年份（如 2025）
   * @param month 月份（1~12）
   */
  async getBillsByMonth(year: number, month: number): Promise<BillRecord[]> {
    const startDate = `${year}-${String(month).padStart(2, '0')}-01`
    const daysInMonth = new Date(year, month, 0).getDate()
    const endDate = `${year}-${String(month).padStart(2, '0')}-${String(daysInMonth).padStart(2, '0')}`

    const options: QueryBillOptions = {
      startDate,
      endDate,
      sortBy: 'date',
      sortOrder: 'asc'
    }

    return this.getBillsByOptions(options)
  }

}
