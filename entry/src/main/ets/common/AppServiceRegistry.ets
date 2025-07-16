import { DBManager } from './services/dbManager';
import { BillService } from './services/billService';
import { StatisticsService } from './services/statisticsService';
import common from '@ohos.app.ability.common';

let billService: BillService;
let statisticsService: StatisticsService;

export async function initServices(context: common.Context) {
  const rdb = await DBManager.initDB(context);
  billService = new BillService(rdb);
  statisticsService = new StatisticsService(rdb);
}

export { billService, statisticsService };
