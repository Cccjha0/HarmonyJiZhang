import { StatisticsOptions, StatisticsResult, CategoryStatItem } from '../models/Bill';
import relationalStore from '@ohos.data.relationalStore';
import { BusinessError } from '@kit.BasicServicesKit';

export class StatisticsService {
  private rdbStore: relationalStore.RdbStore;
  private readonly tableName: string = 'BILL';

  constructor(rdbStore: relationalStore.RdbStore) {
    this.rdbStore = rdbStore;
  }

  /**
   * 获取统计数据
   * @param options 可选的统计条件
   * @returns Promise<StatisticsResult> 收入和支出总额
   */
  async getStatistics(options?: StatisticsOptions): Promise<StatisticsResult> {
    if (!this.rdbStore) {
      console.error('数据库未初始化');
      return { totalIncome: 0, totalExpense: 0 };
    }

    let totalIncome = 0;
    let totalExpense = 0;

    // 查询收入
    const incomePredicates = new relationalStore.RdbPredicates(this.tableName);
    incomePredicates.equalTo('TYPE', '收入');
    if (options?.startDate) {
      incomePredicates.greaterThanOrEqualTo('DATE', options.startDate);
    }
    if (options?.endDate) {
      incomePredicates.lessThanOrEqualTo('DATE', options.endDate);
    }

    // 查询支出
    const expensePredicates = new relationalStore.RdbPredicates(this.tableName);
    expensePredicates.equalTo('TYPE', '支出');
    if (options?.startDate) {
      expensePredicates.greaterThanOrEqualTo('DATE', options.startDate);
    }
    if (options?.endDate) {
      expensePredicates.lessThanOrEqualTo('DATE', options.endDate);
    }

    try {
      // 计算收入总额
      const incomeResultSet = await this.rdbStore.query(incomePredicates, ['AMOUNT']);
      while (incomeResultSet.goToNextRow()) {
        totalIncome += incomeResultSet.getDouble(incomeResultSet.getColumnIndex('AMOUNT'));
      }
      incomeResultSet.close();

      // 计算支出总额
      const expenseResultSet = await this.rdbStore.query(expensePredicates, ['AMOUNT']);
      while (expenseResultSet.goToNextRow()) {
        totalExpense += expenseResultSet.getDouble(expenseResultSet.getColumnIndex('AMOUNT'));
      }
      expenseResultSet.close();

      return { totalIncome, totalExpense };
    } catch (err) {
      const error = err as BusinessError;
      console.error(`获取统计数据失败: ${error.message}`);
      return { totalIncome: 0, totalExpense: 0 };
    }
  }


  /**
   * 按类别分组统计
   * @param type 收入或支出
   * @param options 可选的统计条件
   * @returns Promise<CategoryStatItem[]> 按类别分组的统计结果
   */
  async getCategoryStatistics(
    type: '收入' | '支出',
    options?: StatisticsOptions
  ): Promise<CategoryStatItem[]> {
    if (!this.rdbStore) {
      console.error('数据库未初始化');
      return [];
    }

    const predicates = new relationalStore.RdbPredicates(this.tableName);
    predicates.equalTo('TYPE', type);

    if (options?.startDate) {
      predicates.greaterThanOrEqualTo('DATE', options.startDate);
    }

    if (options?.endDate) {
      predicates.lessThanOrEqualTo('DATE', options.endDate);
    }

    try {
      const resultSet = await this.rdbStore.query(predicates, ['CATEGORY', 'AMOUNT']);

      // 手动分组统计
      const categoryMap = new Map<string, number>();

      while (resultSet.goToNextRow()) {
        const category = resultSet.getString(resultSet.getColumnIndex('CATEGORY'));
        const amount = resultSet.getDouble(resultSet.getColumnIndex('AMOUNT'));

        if (categoryMap.has(category)) {
          categoryMap.set(category, categoryMap.get(category)! + amount);
        } else {
          categoryMap.set(category, amount);
        }
      }

      resultSet.close();

      // 转换为数组并排序
      const result: CategoryStatItem[] = Array.from(categoryMap.entries()).map((entry) => {
        const category = entry[0];
        const total = entry[1];
        return {
          category: category,
          total: total
        } as CategoryStatItem;
      });

      // 按金额降序排序
      result.sort((a, b) => b.total - a.total);

      return result;
    } catch (err) {
      const error = err as BusinessError;
      console.error(`获取类别统计数据失败: ${error.message}`);
      return [];
    }
  }
}