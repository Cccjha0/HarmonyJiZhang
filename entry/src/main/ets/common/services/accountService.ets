import relationalStore from '@ohos.data.relationalStore';
import { BusinessError } from '@kit.BasicServicesKit';
import { Account, AccountRecord } from '../models/Account';

export class AccountService {
  private rdbStore: relationalStore.RdbStore;
  private readonly accountTable = 'ACCOUNT';
  private readonly billTable = 'BILL';

  constructor(rdbStore: relationalStore.RdbStore) {
    this.rdbStore = rdbStore;
  }

  /**
   * 创建账户
   */
  async createAccount(name: string, type: string): Promise<number> {
    const valuesBucket: relationalStore.ValuesBucket = {
      NAME: name,
      TYPE: type
    };

    try {
      const id = await this.rdbStore.insert(this.accountTable, valuesBucket);
      console.info(`创建账户成功 ID: ${id}`);
      return id;
    } catch (err) {
      const error = err as BusinessError;
      console.error(`创建账户失败: ${error.message}`);
      return -1;
    }
  }

  /**
   * 删除账户（级联删除账单）
   */
  async deleteAccount(accountId: number): Promise<boolean> {
    const predicates = new relationalStore.RdbPredicates(this.accountTable);
    predicates.equalTo('ACCOUNT_ID', accountId);

    try {
      const deleted = await this.rdbStore.delete(predicates);
      console.info(`删除账户成功，影响行数: ${deleted}`);
      return deleted > 0;
    } catch (err) {
      const error = err as BusinessError;
      console.error(`删除账户失败: ${error.message}`);
      return false;
    }
  }

  /**
   * 通过AccountId获取账户
   */
  async getAccountById(accountId: number): Promise<AccountRecord> {
    const predicates = new relationalStore.RdbPredicates(this.accountTable);
    predicates.equalTo('ACCOUNT_ID', accountId);

    try {
      const resultSet = await this.rdbStore.query(predicates, ['ACCOUNT_ID', 'NAME', 'TYPE']);
      const account: AccountRecord = {
        id: resultSet.getDouble(resultSet.getColumnIndex('ACCOUNT_ID')),
        name: resultSet.getString(resultSet.getColumnIndex('NAME')),
        type: resultSet.getString(resultSet.getColumnIndex('TYPE'))
      };

      resultSet.close();
      return account;
    } catch (err) {
      const error = err as BusinessError;
      console.error(`获取账户失败: ${error.message}`);
      return {} as AccountRecord;
    }
  }

  /**
   * 获取所有账户
   */
  async getAllAccounts(): Promise<AccountRecord[]> {
    const predicates = new relationalStore.RdbPredicates(this.accountTable);

    try {
      const resultSet = await this.rdbStore.query(predicates, ['ACCOUNT_ID', 'NAME', 'TYPE']);
      const accounts: AccountRecord[] = [];

      while (resultSet.goToNextRow()) {
        accounts.push({
          id: resultSet.getDouble(resultSet.getColumnIndex('ACCOUNT_ID')),
          name: resultSet.getString(resultSet.getColumnIndex('NAME')),
          type: resultSet.getString(resultSet.getColumnIndex('TYPE'))
        });
      }

      resultSet.close();
      return accounts;
    } catch (err) {
      const error = err as BusinessError;
      console.error(`获取账户失败: ${error.message}`);
      return [];
    }
  }

  /**
   * 校准账户余额（收入 - 支出）
   */
  async getAccountBalanceAlign(accountId: number): Promise<number> {
    let totalIncome = 0;
    let totalExpense = 0;

    const incomePred = new relationalStore.RdbPredicates(this.billTable)
      .equalTo('TYPE', '收入')
      .equalTo('ACCOUNT_ID', accountId);

    const expensePred = new relationalStore.RdbPredicates(this.billTable)
      .equalTo('TYPE', '支出')
      .equalTo('ACCOUNT_ID', accountId);

    try {
      // 收入
      const incomeResult = await this.rdbStore.query(incomePred, ['AMOUNT']);
      while (incomeResult.goToNextRow()) {
        totalIncome += incomeResult.getDouble(incomeResult.getColumnIndex('AMOUNT'));
      }
      incomeResult.close();

      // 支出
      const expenseResult = await this.rdbStore.query(expensePred, ['AMOUNT']);
      while (expenseResult.goToNextRow()) {
        totalExpense += expenseResult.getDouble(expenseResult.getColumnIndex('AMOUNT'));
      }
      expenseResult.close();

      return totalIncome - totalExpense;
    } catch (err) {
      const error = err as BusinessError;
      console.error(`获取账户余额失败: ${error.message}`);
      return 0;
    }
  }

  /**
   * 获取账户及其余额（批量）
   */
  async getAllAccountsWithBalance(): Promise<AccountRecord[]> {
    const accounts = await this.getAllAccounts();
    const result: AccountRecord[] = [];

    for (const acc of accounts) {
      const balance = await this.getAccountBalanceAlign(acc.id);
      result.push({
        id: acc.id,
        name: acc.name,
        type: acc.type,
        balance: balance
      });
    }

    return result;
  }
}
