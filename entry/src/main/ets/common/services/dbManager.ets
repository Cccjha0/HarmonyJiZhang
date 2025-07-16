import relationalStore from '@ohos.data.relationalStore';
import common from '@ohos.app.ability.common';

export class DBManager {
  private static rdbStore: relationalStore.RdbStore | null = null;
  private static readonly dbName = 'Bill.db';
  private static readonly tableName = 'BILL';

  static async initDB(context: common.Context): Promise<relationalStore.RdbStore> {
    if (DBManager.rdbStore) return DBManager.rdbStore;

    const config: relationalStore.StoreConfig = {
      name: DBManager.dbName,
      securityLevel: relationalStore.SecurityLevel.S1
    };

    DBManager.rdbStore = await relationalStore.getRdbStore(context, config);
    await DBManager.ensureTableCreated();
    return DBManager.rdbStore;
  }

  private static async ensureTableCreated(): Promise<void> {
    const SQL_CREATE_TABLE = `
      CREATE TABLE IF NOT EXISTS ${DBManager.tableName} (
        BILL_ID INTEGER PRIMARY KEY AUTOINCREMENT,
        DATE TEXT NOT NULL,
        TYPE TEXT CHECK(TYPE IN ('收入', '支出')),
        CATEGORY TEXT,
        AMOUNT REAL,
        REMARK TEXT
      )`;

    await DBManager.rdbStore?.executeSql(SQL_CREATE_TABLE);
  }
}
