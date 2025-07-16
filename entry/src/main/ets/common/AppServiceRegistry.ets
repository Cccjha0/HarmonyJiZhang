import { DBManager } from './services/dbManager';
import { BillService } from './services/billService';
import { StatisticsService } from './services/statisticsService';
import common from '@ohos.app.ability.common';

let billService: BillService;
let statisticsService: StatisticsService;

export async function initServices(context: common.Context) {
  console.info('准备初始化数据库...');
  const rdb = await DBManager.initDB(context);
  console.info('数据库初始化成功');
  billService = new BillService(rdb);
  statisticsService = new StatisticsService(rdb);
  console.info('服务实例创建成功');
}

export { billService, statisticsService };
