import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { initServices } from '../common/AppServiceRegistry';
import type common from '@ohos.app.ability.common';


const DOMAIN = 0x0000;  //try123123212313213213

export default class EntryAbility extends UIAbility {

  async onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): Promise<void> {
    this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
  }


  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  // onWindowStageCreate(windowStage: window.WindowStage): void {
  //   // Main window is created, set main page for this ability
  //   hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');
  //
  //   windowStage.loadContent('pages/Index', (err) => {
  //     if (err.code) {
  //       hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
  //       return;
  //     }
  //     hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
  //   });
  // }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    // 初始化服务（包括数据库）
    const context = this.context as common.UIAbilityContext;
    initServices(context).then(() => {
      hilog.info(DOMAIN, 'testTag', '服务初始化完成');

      // 再加载首页
      windowStage.loadContent('pages/Index', (err) => {
        if (err.code) {
          hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
          return;
        }
        hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
      });
    }).catch((e: Error) => {
      hilog.error(DOMAIN, 'testTag', '服务初始化失败: %{public}s', JSON.stringify(e));
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}