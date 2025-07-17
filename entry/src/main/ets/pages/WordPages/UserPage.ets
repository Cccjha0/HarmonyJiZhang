import { router } from '@kit.ArkUI';
import { common, Want } from '@kit.AbilityKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { image } from '@kit.ImageKit';
import { fileIo as fs } from '@kit.CoreFileKit';

@Entry
@Component
struct UserPage {
  @State message: string = '····这是一个测试界面····';
  @StorageLink('username') username: string = '未登录用户';
  @StorageLink('avatarPath') avatarPath: string = 'app.media.default_avatar';

  @State text_username: string = this.username;  // 直接同步初始值


  private TAG: string = "imageTest";
  @State pixel: image.PixelMap | undefined = undefined;
  @State photoSize: number = 0;
  @State isCrop: boolean = false;
  context: common.UIAbilityContext | undefined = (getContext(this) as common.UIAbilityContext);
  savePath: string = getContext().filesDir;

  build() {
    Column() {
      // 顶部栏
      Row() {
        Image($r('app.media.back')).width(35).height(35).margin({ left: 15, right: 10 })
          .onClick(() => {
            router.back();
          })
        Text('个人信息').fontSize(20).fontWeight(600)
      }
      .justifyContent(FlexAlign.Start)
      .width('100%')
      .margin({ bottom: 20, top: 15, left: 10 })

      // 表单内容
      Column({ space: 24 }) {
        // 头像
        Image(this.avatarPath.startsWith('app.media') ? $r(this.avatarPath) : this.avatarPath)
          .width(120)
          .height(120)
          .borderRadius(60)
          .backgroundColor('#eee')
          .onClick(() => {
            this.getPictureFromAlbum();
          })

        // 用户名输入框
        TextInput({
          text: this.username,
          placeholder: '请输入用户名',
        })
          .width('80%')
          .fontSize(20)
          .padding(12)
          .border({ width: 1, color: '#ccc' })
          .borderRadius(10)
          .onChange((value: string) => {
            this.text_username = value;
            console.log("当前输入值：", value)
          })

        // 保存按钮
        Button('保存并返回')
          .width('80%')
          .height(44)
          .fontSize(18)
          .borderRadius(10)
          .backgroundColor(Color.Black)
          .fontColor('#fff')
          .onClick(() => {
            if (!this.text_username.trim()) {
              this.message = '用户名不能为空';
              return;
            }
            this.username = this.text_username.trim();
            AppStorage.Set('username', this.text_username);
            this.message = '';
            router.back();
          })
      }
      .alignItems(HorizontalAlign.Center)
      .padding(24)
      .width('100%')
      .backgroundColor('#fff')
    }
    .width('100%')
    .height('100%')
  }


  private async getPictureFromAlbum() {
    this.isCrop = false;
    // 拉起相册，选择图片
    let PhotoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
    PhotoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
    PhotoSelectOptions.maxSelectNumber = 1;
    let photoPicker = new photoAccessHelper.PhotoViewPicker();
    let photoSelectResult: photoAccessHelper.PhotoSelectResult = await photoPicker.select(PhotoSelectOptions);
    let albumPath = photoSelectResult.photoUris[0];
    console.info(this.TAG, 'getPictureFromAlbum albumPath= ' + albumPath);
    await this.getImage(albumPath);
  }

  private async getImage(path: string) {
    console.info(this.TAG, 'getImage path: ' + path);
    try {
      // 读取图片为buffer
      const file = fs.openSync(path, fs.OpenMode.READ_ONLY);
      this.photoSize = fs.statSync(file.fd).size;
      console.info(this.TAG, 'Photo Size: ' + this.photoSize);
      let buffer = new ArrayBuffer(this.photoSize);
      fs.readSync(file.fd, buffer);
      fs.closeSync(file);
      // 解码成PixelMap
      const imageSource = image.createImageSource(buffer);
      console.log(this.TAG, 'imageSource: ' + JSON.stringify(imageSource));
      this.pixel = await imageSource.createPixelMap({});
      this.avatarPath = path;   // 更新头像路径
      AppStorage.Set('avatarPath', path); // 存储头像路径
    } catch (e) {
      console.info(this.TAG, 'getImage e: ' + JSON.stringify(e));
    }
  }
}