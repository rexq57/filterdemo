//
//  FilterViewController.m
//  FiltersDemo
//
//  Created by rexq57 on 2017/4/16.
//  Copyright © 2017年 rexq57. All rights reserved.
//

#import "FilterViewController.h"
#import <GPUImage.h>
#import <objc/runtime.h>

#import "FilterCollectionViewCell.h"
#include <map>
#include <string>
#include <vector>

using namespace std;

enum OPERATION
{
    OPERATION_MAPPING = 0,
    OPERATION_BLEND_SCREEN,
    OPERATION_BLEND_OVERLAY
};

struct Texture
{
    string name;
    OPERATION operation;
    
    Texture(string name, OPERATION operation)
    {
        this->name = name;
        this->operation = operation;
    }
};

struct Filter
{
    string name;
    
    vector<Texture> textures;
};

vector<Filter> filters = {
    
    // Instagram
    {"Clarendon", {{"Clarendon.png", OPERATION_MAPPING}}},
    {"Gingham", {{"Gingham.png", OPERATION_MAPPING}}},
    {"Moon", {{"Moon.png", OPERATION_MAPPING}}},
    {"Lark", {{"Lark.png", OPERATION_MAPPING}}},
    {"Reyes", {{"Reyes.png", OPERATION_MAPPING}}},
    
    // B612
    {"Gleam", {{"Gleam.png", OPERATION_MAPPING}}},
    {"Youth", {{"Youth.png", OPERATION_MAPPING}}},
    {"Purity", {{"Purity.png", OPERATION_MAPPING}}},
    {"Adore", {{"Adore.png", OPERATION_MAPPING}}},
    {"Heart", {{"Heart.png", OPERATION_MAPPING}}},
    {"Golden", {{"Golden.png", OPERATION_MAPPING}, {"Golden_Screen.png", OPERATION_BLEND_SCREEN}}},
    
    // Snow
    {"Pretty", {{"Pretty.png", OPERATION_MAPPING}}},
    {"Baby", {{"Baby.png", OPERATION_MAPPING}}},
    {"Fresh", {{"Fresh.png", OPERATION_MAPPING}}},
    {"Light", {{"Light.png", OPERATION_MAPPING}}},
    {"Apple Mint", {{"Apple Mint.png", OPERATION_MAPPING}}},
    
    // VSCO
    {"a1", {{"a1.png", OPERATION_MAPPING}}},
    {"b1", {{"b1.png", OPERATION_MAPPING}}},
    {"c1", {{"c1.png", OPERATION_MAPPING}}},
    {"e1", {{"e1.png", OPERATION_MAPPING}}},
    {"f1", {{"f1.png", OPERATION_MAPPING}}},
    {"j1", {{"j1.png", OPERATION_MAPPING}}},
    
    // Philm
    // 卷积神经网络滤镜，hahaha
    
    // 以下APP的滤镜太low，有时间再弄
    
    // Camera360
    
    // 脑残秀秀
    
    // 幼稚相机
};

// 将外部对象添加到自身引用，防止其被释放（例如 GPUImagePicture）
@interface GPUImageFilter(Retained)

- (void) addObj:(id) obj;

@end

@implementation GPUImageFilter(Retained)
static id kArray;

- (void) addObj:(id) obj
{
    NSMutableArray *array = objc_getAssociatedObject(self, &kArray);
    if (array == nil)
    {
        array = [NSMutableArray array];
        objc_setAssociatedObject(self, &kArray, array, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    [array addObject:obj];
}


@end


@interface FilterViewController ()
{
    IBOutlet GPUImageView* _displayView;
    IBOutlet UICollectionView* _filtersView;
    
    GPUImageVideoCamera* _camera;
    GPUImageTransformFilter* _transformFilter;
    
    
}

@end

@implementation FilterViewController

- (id) initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder]))
    {
        _camera = ({
            
            GPUImageVideoCamera *camera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1280x720 cameraPosition:AVCaptureDevicePositionBack];
            
            camera.outputImageOrientation = UIInterfaceOrientationPortrait;
            camera.horizontallyMirrorFrontFacingCamera = YES;
            camera.horizontallyMirrorRearFacingCamera = NO;
            
            [camera.captureSession.outputs enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([obj isKindOfClass:[AVCaptureVideoDataOutput class]])
                {
                    [(AVCaptureVideoDataOutput*)obj setAlwaysDiscardsLateVideoFrames:YES];
                }
            }];
            camera;
        });

        [_camera startCameraCapture];
        
        _transformFilter = ({
            
        
            GPUImageTransformFilter* transformFilter = [GPUImageTransformFilter new];
            transformFilter.transform3D = CATransform3DMakeScale(1, 1, 1);
            
            transformFilter;
        });
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _displayView.fillMode = kGPUImageFillModePreserveAspectRatioAndFill;
    [_filtersView selectItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:NO scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];

    [_camera addTarget:_transformFilter];
    [_transformFilter addTarget:_displayView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void) generateFilter:(Filter) filter in_filter:(GPUImageFilter**)filter1 out_filter:(GPUImageFilter**)filter2
{
    vector<Texture> textures = filter.textures;
    
    GPUImageFilter* in_filter = nil;
    GPUImageFilter* out_filter = nil;
    GPUImageFilter* prev_filter = nil;
    
    for (int i=0; i<textures.size(); i++) {
        
        Texture tex = textures[i];
        GPUImageFilter* filter;
        
        switch (tex.operation) {
            case OPERATION_MAPPING:
            {
                filter = [GPUImageLookupFilter new];
                [filter addObj:({
                    
                    GPUImagePicture* pic = [[GPUImagePicture alloc] initWithImage:[UIImage imageNamed:[NSString stringWithUTF8String:tex.name.c_str()]]];
                    [pic addTarget:filter atTextureLocation:1];
                    [pic processImage];
                    
                    pic;
                })];
                
                break;
            }
            case OPERATION_BLEND_SCREEN:
            {
                filter = [GPUImageScreenBlendFilter new];
                [filter addObj:({
                    
                    GPUImagePicture* pic = [[GPUImagePicture alloc] initWithImage:[UIImage imageNamed:[NSString stringWithUTF8String:tex.name.c_str()]]];
                    [pic addTarget:filter atTextureLocation:1];
                    [pic processImage];
                    
                    pic;
                })];
                
                break;
            }
            default:
                break;
        }
        
        if (in_filter == nil)
        {
            in_filter = filter;
        }
        if (i == textures.size()-1)
        {
            out_filter = filter;
        }
        
        if (prev_filter)
            [prev_filter addTarget:filter atTextureLocation:0];
        
        prev_filter = filter;
    }
    
    *filter1 = in_filter;
    *filter2 = out_filter;
}

#pragma mark -
#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return 1 + filters.size();
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    FilterCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"FilterCell" forIndexPath:indexPath];
    
    int filterIndex = (int)indexPath.row - 1;
    UIImage* normalImage = [UIImage imageNamed:@"Normal.png"];
    
    if (indexPath.row == 0)
    {
        cell.name = @"Normal";
        cell.image = normalImage;
    }
    else
    {
        cell.name = [NSString stringWithUTF8String:filters[filterIndex].name.c_str()];
        
        GPUImageFilter* in_filter, *out_filter;

        [self generateFilter:filters[filterIndex] in_filter:&in_filter out_filter:&out_filter];
        
        [in_filter addObj:({
            
            GPUImagePicture* originalPic = [[GPUImagePicture alloc] initWithImage:normalImage];
            [originalPic addTarget:in_filter atTextureLocation:0];
            [originalPic processImage];
            
            originalPic;
        })];
        
        [out_filter useNextFrameForImageCapture];
        cell.image = [out_filter imageFromCurrentFramebuffer];
    }
    
    return cell;
}

#pragma mark -
#pragma mark - UICollectionViewDelegate

void unlink(GPUImageOutput* output)
{
    [[output targets] enumerateObjectsUsingBlock:^(GPUImageOutput* obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj respondsToSelector:@selector(targets)])
        {
            unlink(obj);
        }
    }];
    [output removeAllTargets];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    unlink(_transformFilter);
    
    int filterIndex = (int)indexPath.row - 1;
    if (filterIndex >= 0)
    {
        GPUImageFilter* in_filter, *out_filter;
        [self generateFilter:filters[filterIndex] in_filter:&in_filter out_filter:&out_filter];
        [_transformFilter addTarget:in_filter];
        [out_filter addTarget:_displayView];
    }
    else
    {
        [_transformFilter addTarget:_displayView];
    }

    [_filtersView selectItemAtIndexPath:indexPath animated:YES scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
}



@end
