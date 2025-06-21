import router from '@ohos.router';
import http from '@ohos.net.http';

interface WallpaperEntry {
  id: number;
  imageUrl: string;
  title: string;
  description: string;
  date: string; // e.g., "YYYY-MM-DD"
}

// 定义 Bing API 返回的图片数据结构
interface BingImage {
  startdate: string;
  fullstartdate: string;
  enddate: string;
  url: string;
  urlbase: string;
  copyright: string;
  copyrightlink: string;
  title: string;
  quiz: string;
  wp: boolean;
  hsh: string;
  drk: number;
  top: number;
  bot: number;
  // 移除 hs 字段，因为它未被使用且导致 any 类型错误
}

// 定义 Bing API 的 tooltips 结构
interface Tooltips {
  quickfact: string;
  full: string;
}

// 定义 Bing API 的顶层响应结构
interface BingApiResponse {
  images: BingImage[];
  tooltips: Tooltips; // 使用定义的 Tooltips 接口
}

// 新增：历史壁纸列表项组件
@Component
struct HistoryListItem {
  @Prop item: WallpaperEntry;

  build() {
    Row() {
      Image(this.item.imageUrl)
        .width(130)
        .height(90)
        .objectFit(ImageFit.Cover)
        .borderRadius(12)
        .shadow({ radius: 10, color: '#00000033', offsetX: 0, offsetY: 2 });

      Column() {
        Text(this.item.title)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFF')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ bottom: 8 });

        Text(this.item.date)
          .fontSize(12)
          .fontColor('#FFFFFF')
          .opacity(0.7);
      }
      .layoutWeight(1)
      .padding({ left: 16 })
      .alignItems(HorizontalAlign.Start);
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#00000033')
    .borderRadius(16)
    .onClick(() => {
      router.pushUrl({ url: 'pages/DetailPage', params: { wallpaper: this.item } });
    });
  }
}

@Entry
@Component
struct Index {
  @State wallpapers: WallpaperEntry[] = [];
  @State isLoading: boolean = true;
  @State isDownloading: boolean = false; // 此状态仅在 DetailPage 中使用，但为了兼容性保留
  @State layoutMode: 'grid' | 'list' = 'grid'; // 新增：布局模式状态

  aboutToAppear() {
    this.fetchBingWallpapers();
  }

  async fetchBingWallpapers() {
    try {
      this.isLoading = true;
      const response = await http.createHttp().request(
        'https://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=10&mkt=zh-CN',
        { method: http.RequestMethod.GET }
      );

      if (response.responseCode === http.ResponseCode.OK) {
        const data: BingApiResponse = JSON.parse(response.result as string); // 明确类型化 JSON.parse 的结果
        const images: BingImage[] = data.images;

        this.wallpapers = images.map((img: BingImage, index: number) => {
          const imageUrl = `https://www.bing.com${img.url}`;
          const copyright = img.copyright;
          const title = img.title && img.title.length > 0 ? img.title : copyright.split(' (')[0] || '无标题';
          const description = copyright || '无描述';

          const dateStr = img.startdate;
          const year = dateStr.substring(0, 4);
          const month = dateStr.substring(4, 6);
          const day = dateStr.substring(6, 8);
          const formattedDate = `${year}-${month}-${day}`;

          return {
            id: index + 1,
            imageUrl: imageUrl,
            title: title,
            description: description,
            date: formattedDate
          } as WallpaperEntry; // 显式类型断言
        });
      } else {
        console.error('从 Bing API 获取壁纸失败:', response.responseCode);
        this.wallpapers = this.getMockWallpapers();
      }
    } catch (error) {
      console.error('获取壁纸时发生错误:', error);
      this.wallpapers = this.getMockWallpapers();
    } finally {
      this.isLoading = false;
    }
  }

  getMockWallpapers(): WallpaperEntry[] {
    return [
      {
        id: 1,
        imageUrl: 'https://www.bing.com/th?id=OHR.SunriseCastle_ZH-CN1234567890_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp',
        title: '杜布罗夫尼克古城日出 (模拟)',
        description: '克罗地亚达尔马提亚地区的杜布罗夫尼克古城，清晨的阳光洒在古老的石板路上，宁静而美丽。 (模拟数据)',
        date: '2023-10-26'
      } as WallpaperEntry, // 显式类型断言
      {
        id: 2,
        imageUrl: 'https://www.bing.com/th?id=OHR.SeaLionPup_ZH-CN1234567890_1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp',
        title: '海狮幼崽 (模拟)',
        description: '加拿大不列颠哥伦比亚省温哥华岛附近，一只可爱的海狮幼崽在水中嬉戏。 (模拟数据)',
        date: '2023-10-25'
      } as WallpaperEntry // 显式类型断言
    ];
  }

  async downloadAndSetWallpaper(imageUrl: string) {
    console.log('Download and set wallpaper called from Index, this should be handled in DetailPage.');
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      if (this.wallpapers.length > 0) {
        Image(this.wallpapers[0].imageUrl)
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
          .blur(20)
          .opacity(0.3);
      } else {
      }

      Column() {
        Row() {
          Text('Bing 壁纸')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF');
          Blank();
          // 更新：使用新创建的自定义刷新图标
          Button({ type: ButtonType.Circle }) {
            Image($r('app.media.ic_refresh'))
              .width(22)
              .height(22)
              .fillColor(Color.Black)
          }
          .width(40)
          .height(40)
          .backgroundColor('#FFFFFF')
          .onClick(() => this.fetchBingWallpapers());
        }
        .width('100%')
        .height(56)
        .padding({ left: 16, right: 16 })
        .backgroundColor('#00000033')
        .justifyContent(FlexAlign.SpaceBetween);

        if (this.isLoading) {
          LoadingProgress()
            .width(50)
            .height(50)
            .color('#FFFFFF')
            .layoutWeight(1);
        } else if (this.wallpapers.length > 0) {
          Scroll() {
            Column() {
              Column() {
                Image(this.wallpapers[0].imageUrl)
                  .width('100%')
                  .height(280)
                  .objectFit(ImageFit.Cover)
                  .borderRadius(16)
                  .shadow({ radius: 20, color: '#00000033', offsetX: 0, offsetY: 4 });

                Column() {
                  Text(this.wallpapers[0].title)
                    .fontSize(22)
                    .fontWeight(FontWeight.Bold)
                    .margin({ bottom: 8 })
                    .fontColor('#FFFFFF');

                  Text(this.wallpapers[0].description)
                    .fontSize(16)
                    .opacity(0.8)
                    .fontColor('#FFFFFF')
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .margin({ bottom: 16 });
                }
                .width('100%')
                .padding(16)
                .backgroundColor('#00000033')
                .borderRadius(16);
              }
              .width('100%')
              .padding(16)
              .margin({ bottom: 16 })
              .onClick(() => {
                router.pushUrl({ url: 'pages/DetailPage', params: { wallpaper: this.wallpapers[0] } });
              });

              if (this.wallpapers.length > 1) {
                // 新增：历史壁纸标题和布局切换按钮
                Row() {
                  Text('历史壁纸')
                    .fontSize(20)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#FFFFFF');
                  Blank();
                  Button({ type: ButtonType.Circle }) {
                    // 修正：由于系统图标资源不可用，暂时替换为文字按钮
                    Text(this.layoutMode === 'grid' ? ':::' : '::') // 列表/网格
                      .fontSize(16)
                      .fontWeight(FontWeight.Bold)
                      .fontColor(Color.Black)
                  }
                  .width(36)
                  .height(36)
                  .backgroundColor('#FFFFFF')
                  .onClick(() => {
                    this.layoutMode = this.layoutMode === 'grid' ? 'list' : 'grid';
                  });
                }
                .width('100%')
                .padding({ left: 16, right: 16, bottom: 16 });

                // 新增：根据布局模式条件渲染 Grid 或 List
                if (this.layoutMode === 'grid') {
                  Grid() {
                    ForEach(this.wallpapers.slice(1), (item: WallpaperEntry) => {
                      GridItem() {
                        Column() {
                          Image(item.imageUrl)
                            .width('100%')
                            .height(150) // 放大
                            .objectFit(ImageFit.Cover)
                            .borderRadius(12)
                            .shadow({ radius: 10, color: '#00000033', offsetX: 0, offsetY: 2 });

                          Text(item.title)
                            .fontSize(14)
                            .fontWeight(FontWeight.Medium)
                            .fontColor('#FFFFFF')
                            .maxLines(2)
                            .textOverflow({ overflow: TextOverflow.Ellipsis })
                            .margin({ top: 8, bottom: 4 });

                          Text(item.date)
                            .fontSize(12)
                            .fontColor('#FFFFFF')
                            .opacity(0.7);
                        }
                        .padding(8)
                        .backgroundColor('#00000033')
                        .borderRadius(12)
                        .onClick(() => {
                          router.pushUrl({ url: 'pages/DetailPage', params: { wallpaper: item } });
                        });
                      }
                    });
                  }
                  .columnsTemplate('1fr 1fr')
                  .columnsGap(12)
                  .rowsGap(12)
                  .padding({ left: 16, right: 16, bottom: 16 });
                } else {
                  // 修正：减小 List 的间距
                  List({ space: 8 }) {
                    ForEach(this.wallpapers.slice(1), (item: WallpaperEntry) => {
                      ListItem() {
                        // 使用新的列表项组件
                        HistoryListItem({ item: item });
                      }
                    });
                  }
                  .width('100%')
                  .padding({ left: 16, right: 16, bottom: 16 });
                }
              }
            }
            .width('100%');
          }
          .layoutWeight(1);
        } else {
          Text('没有找到壁纸，请稍后重试或刷新。')
            .fontSize(18)
            .fontColor('#FFFFFF')
            .layoutWeight(1);
        }
      }
      .width('100%')
      .height('100%');
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000');
  }
}