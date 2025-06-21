import router from '@ohos.router';
import http from '@ohos.net.http';
import image from '@ohos.multimedia.image';
import media from '@ohos.multimedia.media';
import abilityAccessCtrl from '@ohos.abilityAccessCtrl';
import fs from '@ohos.file.fs';
import common from '@ohos.app.ability.common';

interface WallpaperEntry {
  id: number;
  imageUrl: string;
  title: string;
  description: string;
  date: string; // e.g., "2023-10-26"
}

// 新增：操作栏按钮组件
@Component
struct ActionButton {
  label: string;
  icon: Resource;
  action: () => void;
  @State isLoading: boolean = false;

  build() {
    Column() {
      if (this.isLoading) {
        LoadingProgress()
          .width(24)
          .height(24)
          .color(Color.White)
          .margin({ bottom: 4 });
      } else {
        Image(this.icon)
          .width(24)
          .height(24)
          .fillColor(Color.White)
          .margin({ bottom: 4 });
      }
      Text(this.label)
        .fontSize(12)
        .fontColor(Color.White);
    }
    .width(80)
    .height(60)
    .justifyContent(FlexAlign.Center)
    .onClick(() => this.action());
  }
}

@Entry
@Component
struct DetailPage {
  @State wallpaper: WallpaperEntry | null = null;
  @State isDownloading: boolean = false;
  @State isSettingWallpaper: boolean = false;
  private infoSheetIsShow: boolean = false; // 控制信息弹窗的显示

  aboutToAppear() {
    let params = router.getParams();
    if (params && params.wallpaper) {
      this.wallpaper = params.wallpaper as WallpaperEntry;
    }
  }

  async checkAndRequestPermission(): Promise<boolean> {
    let context = getContext(this) as common.UIAbilityContext;
    let atManager = abilityAccessCtrl.createAtManager();
    try {
      let grantStatus = await atManager.checkAccessToken(context.tokenID, 'ohos.permission.WRITE_MEDIA');
      if (grantStatus === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        return true;
      }
      let res = await atManager.requestPermissionsFromUser(context, ['ohos.permission.WRITE_MEDIA']);
      if (res.authResults[0] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        return true;
      }
      AlertDialog.show({
        title: '权限申请失败',
        message: '缺少写入媒体权限，无法继续操作。',
        confirm: { value: '确定', action: () => {} }
      });
      return false;
    } catch (err) {
      console.error('权限申请异常:', err);
      return false;
    }
  }

  async downloadWallpaper() {
    if (!this.wallpaper || this.isDownloading) return;
    if (!await this.checkAndRequestPermission()) return;

    this.isDownloading = true;
    try {
      const httpRequest = http.createHttp();
      const data = await httpRequest.request(this.wallpaper.imageUrl, { method: http.RequestMethod.GET });
      if (data.responseCode !== http.ResponseCode.OK) {
        throw new Error(`下载失败: ${data.responseCode}`);
      }
      const buffer = data.result as ArrayBuffer;
      const context = getContext(this) as common.UIAbilityContext;
      const fileName = `bing_wallpaper_${this.wallpaper.date}_${Date.now()}.jpg`;
      const filePath = `${context.cacheDir}/${fileName}`;

      const file = await fs.open(filePath, fs.OpenMode.CREATE | fs.OpenMode.WRITE);
      await fs.write(file.fd, buffer);
      await fs.close(file);
      await media.addImage(filePath);

      AlertDialog.show({
        title: '成功',
        message: '壁纸已成功下载并保存到相册。',
        confirm: { value: '确定', action: () => {} }
      });
    } catch (error) {
      AlertDialog.show({
        title: '下载失败',
        message: `下载失败，请重试: ${error.message || error}`,
        confirm: { value: '确定', action: () => {} }
      });
    } finally {
      this.isDownloading = false;
    }
  }

  async setWallpaper() {
    // HarmonyOS 中，设置壁纸通常需要系统应用权限或特殊的API调用。
    // 对于普通应用，最友好的方式是引导用户手动设置。
    // 这里我们仅模拟下载成功的提示，实际逻辑与 downloadWallpaper 一致。
    AlertDialog.show({
      title: '提示',
      message: '壁纸已下载并保存到相册，请前往系统"设置"或"图库"手动设置为壁纸。',
      confirm: { value: '好的', action: () => {} }
    });
    await this.downloadWallpaper(); // 调用下载逻辑
  }

  build() {
    if (!this.wallpaper) {
      Text('加载壁纸信息失败...')
        .fontSize(20)
        .fontColor(Color.White)
        .height('100%')
        .width('100%')
        .justifyContent(FlexAlign.Center);
      return;
    }

    Stack() {
      // 全屏背景
      Image(this.wallpaper.imageUrl)
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)
        .hitTestBehavior(HitTestMode.None);

      // 修正：使用一个全屏的 Column 来容纳顶栏和底栏
      Column() {
        // 顶部返回栏
        Row() {
          // 假设您已有名为 ic_back.svg 的返回图标，如果没有，请创建或替换为文字
          Image($r('app.media.ic_back'))
            .width(28)
            .height(28)
            .fillColor(Color.White)
            .shadow({ radius: 10, color: '#00000088' })
            .onClick(() => router.back());
        }
        .width('100%')
        .height(56)
        .padding({ left: 16, right: 16 })
        .justifyContent(FlexAlign.Start);

        // 使用 Blank 组件将底部操作栏推至屏幕底部
        Blank()

        // 底部悬浮操作栏
        Row() {
          ActionButton({
            label: '设为壁纸',
            // 假设您有名为 ic_set_wallpaper.svg 的图标
            icon: $r('app.media.ic_set_wallpaper'),
            action: () => this.setWallpaper(),
            isLoading: this.isSettingWallpaper
          })
          ActionButton({
            label: '下载',
            // 假设您有名为 ic_download.svg 的图标
            icon: $r('app.media.ic_download'),
            action: () => this.downloadWallpaper(),
            isLoading: this.isDownloading
          })
          ActionButton({
            label: '信息',
            // 假设您有名为 ic_info.svg 的图标
            icon: $r('app.media.ic_info'),
            action: () => { this.infoSheetIsShow = true; }
          })
        }
        .width('90%')
        .height(80)
        .backgroundColor('#00000088')
        .borderRadius(20)
        .justifyContent(FlexAlign.SpaceEvenly)
        .margin({ bottom: 32 }); // 使用 margin 调整与屏幕底部的距离
      }
      .width('100%')
      .height('100%')
      .hitTestBehavior(HitTestMode.Default);
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Black)
    // 信息弹窗
    .sheet(this.isShowing('infoSheet'), this.wallpaperBuilder)
  }

  // 用于控制弹窗的辅助函数
  isShowing(sheetName: string): boolean {
    if (sheetName === 'infoSheet') {
      return this.infoSheetIsShow;
    }
    return false;
  }

  // 信息弹窗的构建器
  @Builder wallpaperBuilder() {
    Column() {
      if (this.wallpaper) {
        Text(this.wallpaper.title)
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 24, bottom: 12 });
        Text(this.wallpaper.date)
          .fontSize(16)
          .opacity(0.7)
          .margin({ bottom: 20 });
        Scroll() {
          Text(this.wallpaper.description)
            .fontSize(18)
            .lineHeight(24)
            .width('90%');
        }
        .layoutWeight(1)
        .margin({ bottom: 24 });
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16 });
  }
}