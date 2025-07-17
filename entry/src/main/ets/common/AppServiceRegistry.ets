import { DBManager } from './services/dbManager';
import { BillService } from './services/billService';
import { StatisticsService } from './services/statisticsService';
import { AccountService } from './services/accountService';
import common from '@ohos.app.ability.common';

let billService: BillService;
let statisticsService: StatisticsService;
let accountService: AccountService;

export async function initServices(context: common.Context) {
  const rdb = await DBManager.initDB(context);
  billService = new BillService(rdb);
  statisticsService = new StatisticsService(rdb);
  accountService = new AccountService(rdb);
}

export { billService, statisticsService, accountService };
