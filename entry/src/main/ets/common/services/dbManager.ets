import relationalStore from '@ohos.data.relationalStore';
import common from '@ohos.app.ability.common';

export class DBManager {
  private static rdbStore: relationalStore.RdbStore | null = null;
  private static readonly dbName = 'Bill.db';

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
    let SQL_CREATE_TABLE = `
    CREATE TABLE IF NOT EXISTS ACCOUNT (
        ACCOUNT_ID INTEGER PRIMARY KEY AUTOINCREMENT,
        NAME TEXT NOT NULL,
        TYPE TEXT,
        BALANCE REAL DEFAULT 0,
        REMARK TEXT
      )`;

    await DBManager.rdbStore?.executeSql(SQL_CREATE_TABLE);

    SQL_CREATE_TABLE = `
      CREATE TABLE IF NOT EXISTS BILL (
        BILL_ID INTEGER PRIMARY KEY AUTOINCREMENT,
        DATE TEXT NOT NULL,
        TYPE TEXT CHECK(TYPE IN ('收入', '支出')),
        CATEGORY TEXT,
        AMOUNT REAL,
        REMARK TEXT,
        ACCOUNT_ID INTEGER NOT NULL,
        FOREIGN KEY (ACCOUNT_ID) REFERENCES ACCOUNT(ACCOUNT_ID)
      )`;

    await DBManager.rdbStore?.executeSql(SQL_CREATE_TABLE);
  }
}
