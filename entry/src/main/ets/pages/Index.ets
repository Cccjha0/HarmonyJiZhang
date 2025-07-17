import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import { BillRecord, CategoryStatItem, StatisticsResult, StatisticsOptions } from '../common/models/Bill';
import promptAction from '@ohos.promptAction';
import { billService, statisticsService } from '../common/AppServiceRegistry'
import Tabss from './Tabss';


AppStorage.Set('username', AppStorage.Get('username') ?? '未登录用户')
AppStorage.Set('avatarPath', AppStorage.Get('avatarPath') ?? 'app.media.default_avatar')

//选择器选项接口
interface SelectOption {
  value: string;
}

//删除确认对话框参数
class DeleteDialogParams {
  title: string = '确认删除';
  message: string = '确定要删除这条账单记录吗？';
  cancel: () => void = () => console.info('取消删除');
  confirm: () => void = () => console.info('确认删除');
}

@Entry
@Component
struct Index {
  aboutToAppear() {
    // 页面一显示就跳转到Tabss页面
    router.pushUrl({
      url: "pages/Tabss"
    });
  }

  build() {
    //必须有一个布局容器组件
    Column() {
      Tabss();
    }.width('100%')
    .height('100%')
    //整个窗口背景为灰白
    .backgroundColor('#eee')
  }
}

