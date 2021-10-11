unit uMain;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, StdCtrls, ExtCtrls, ImgList,

  SetupAPI,
  DeviceHelper;

type
  TdlgMain = class(TForm)
    tvDevices: TTreeView;
    pnSetting: TPanel;
    cbShowHidden: TCheckBox;
    ilDevices: TImageList;
    lvAdvancedInfo: TListView;
    Splitter1: TSplitter;
    StatusBar: TStatusBar;
    procedure FormCreate(Sender: TObject);
    procedure cbShowHiddenClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure tvDevicesCompare(Sender: TObject; Node1, Node2: TTreeNode;
      Data: Integer; var Compare: Integer);
    procedure lvAdvancedInfoCompare(Sender: TObject; Item1, Item2: TListItem;
      Data: Integer; var Compare: Integer);
    procedure tvDevicesChange(Sender: TObject; Node: TTreeNode);
  private
    hAllDevices: HDEVINFO;
    ClassImageListData: TSPClassImageListData;
    DeviceHelper: TDeviceHelper;
  private
    procedure InitImageList;
    procedure ReleaseImageList;
    function FindRootNode(const DeviceClassName: String): TTreeNode;
  public
    procedure InitDeviceList;
    procedure FillDeviceList;
    procedure ReleaseDeviceList;
    procedure ShowDeviceAdvancedInfo(const DeviceIndex: Integer);
    procedure ShowDeviceInterfaces(const DeviceIndex: Integer);
    function GetDeviceImageIndex(DeviceGUID: TGUID): Integer;
  end;

var
  dlgMain: TdlgMain;

implementation

{$R *.dfm}

uses
  ListViewHelper;

{ TdlgMain }

procedure TdlgMain.cbShowHiddenClick(Sender: TObject);
begin
  tvDevices.Items.Clear;
  ReleaseDeviceList;
  InitDeviceList;
  FillDeviceList;
    
end;

procedure TdlgMain.FillDeviceList;
var
  dwIndex: DWORD;  
  DeviceInfoData: SP_DEVINFO_DATA;
  DeviceName, DeviceClassName: String;
  tvRoot: TTreeNode;
  ClassGUID: TGUID;
  DeviceClassesCount, DevicesCount: Integer;
begin

  tvDevices.Items.BeginUpdate;
  try
    dwIndex := 0;
    DeviceClassesCount := 0;
    DevicesCount := 0;

    // �������������� ��������� ��� ��������� ����������
    ZeroMemory(@DeviceInfoData, SizeOf(SP_DEVINFO_DATA));
    DeviceInfoData.cbSize := SizeOf(SP_DEVINFO_DATA);

    // �������� ������ �� ������� ���������� � DIS
    // ����� ���������� ���������� � dwIndex
    while SetupDiEnumDeviceInfo(hAllDevices, dwIndex, DeviceInfoData) do
    begin

      // �������������� ��� DeviceHelper,
      // ���������� ������ � SP_DEVINFO_DATA ����� �����������
      // ��� ������ ������� ������� ������
      DeviceHelper.DeviceInfoData := DeviceInfoData;

      // �������� ����������� ��� ����������
      DeviceName := DeviceHelper.FriendlyName;
      // ���� ������������ ����� ��� -
      // �������� ��� ���������� �� ���������
      if DeviceName = '' then
        DeviceName := DeviceHelper.Description;

      // �������� GUID ������, � �������� ��������� ����������
      ClassGUID := DeviceHelper.ClassGUID;
      // �������� ��� ������, � �������� ��������� ����������
      DeviceClassName := DeviceHelper.DeviceClassDescription(ClassGUID);

      // ���� �����, � ������� ��������� ��� ������ �� ������
      tvRoot := FindRootNode(DeviceClassName);
      if tvRoot = nil then
      begin
        // ���� �� �����, ������� ��
        tvRoot := tvDevices.Items.Add(nil, DeviceClassName);
        // ���������� ������ ������ �� GUID-� ������
        tvRoot.ImageIndex :=
          GetDeviceImageIndex(ClassGUID);
        tvRoot.SelectedIndex := tvRoot.ImageIndex;
        tvRoot.StateIndex := -1;
        Inc(DeviceClassesCount);
      end;

      // ��������� � ����� ������ ����� ����������
      with tvDevices.Items.AddChild(tvRoot, DeviceName) do
      begin
        // ���������� ������ ������ �� GUID-� ����������
        ImageIndex :=
          GetDeviceImageIndex(DeviceInfoData.ClassGuid);
        SelectedIndex := ImageIndex;
        // StateIndex ����� ��������� ������ ���������� � DIS
        // ��� ����������� ��� ���������� ������ �� �������
        StateIndex := Integer(dwIndex);
        Inc(DevicesCount);
      end;

      // ��������� � ���������� ���������
      Inc(dwIndex);
    end;

    tvDevices.AlphaSort;
    StatusBar.Panels[0].Text := 'DeviceClasses Count: ' +
      IntToStr(DeviceClassesCount);
    StatusBar.Panels[1].Text := 'Devices Count: ' +
      IntToStr(DevicesCount);
    
  finally
    tvDevices.Items.EndUpdate;
  end;
end;

function TdlgMain.FindRootNode(const DeviceClassName: String): TTreeNode;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to tvDevices.Items.Count - 1 do
    if tvDevices.Items[I].Level = 0 then
      if tvDevices.Items[I].Text = DeviceClassName then
      begin
        Result := tvDevices.Items[I];
        Break;
      end;
end;

procedure TdlgMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  ReleaseImageList;
  DeviceHelper.Free;
  ReleaseDeviceList;
end;

procedure TdlgMain.FormCreate(Sender: TObject);
begin
  lvAdvancedInfo.DoubleBuffered := True;
  if not LoadSetupApi then
    RaiseLastOSError;
  DeviceHelper := TDeviceHelper.Create;
  InitImageList;
  InitDeviceList;
  FillDeviceList;
end;

function TdlgMain.GetDeviceImageIndex(DeviceGUID: TGUID): Integer;
begin
  Result := -1;
  // �������� ������ ������ ��� ����������� ����������
  SetupDiGetClassImageIndex(ClassImageListData, DeviceGUID, Result);
end;

procedure TdlgMain.InitDeviceList;
const
  PINVALID_HANDLE_VALUE = Pointer(INVALID_HANDLE_VALUE);
var
  dwFlags: DWORD;
begin
  // ������������� ����������� ����� ����� ������� �������
  dwFlags := DIGCF_ALLCLASSES;// or DIGCF_DEVICEINTERFACE;
  if not cbShowHidden.Checked then
    dwFlags := dwFlags or DIGCF_PRESENT; // ���������� ������ ������������� ����������

  // ������� � ��������� DIS (Device Information Sets)
  // ����������� �� ���� ������������� �����������
  hAllDevices := SetupDiGetClassDevsExA(nil, nil, 0,
    dwFlags, nil, nil, nil);
  if hAllDevices = PINVALID_HANDLE_VALUE then RaiseLastOSError;
  DeviceHelper.DeviceListHandle := hAllDevices;
end;

procedure TdlgMain.InitImageList;
begin
  // �������� ����� ImageList-� � ������� ���������
  // ����������� ����� ��������� � ��������� ���� �����
  // ������ ImageList-� ���������� � ������� ���������
  ZeroMemory(@ClassImageListData, SizeOf(TSPClassImageListData));
  ClassImageListData.cbSize := SizeOf(TSPClassImageListData);
  if SetupDiGetClassImageList(ClassImageListData) then
    ilDevices.Handle := ClassImageListData.ImageList;
end;

procedure TdlgMain.lvAdvancedInfoCompare(Sender: TObject; Item1,
  Item2: TListItem; Data: Integer; var Compare: Integer);
begin
  Compare := CompareText(Item1.Caption, Item2.Caption);
end;

procedure TdlgMain.ReleaseDeviceList;
begin
   // �� �������� ��������� ��������� ����� DIS
   SetupDiDestroyDeviceInfoList(hAllDevices);
end;

procedure TdlgMain.ReleaseImageList;
begin
  // ��� �������� ��������� ��������� ���������� ����� ImageList
  if not SetupDiDestroyClassImageList(ClassImageListData) then
    RaiseLastOSError;
end;

procedure TdlgMain.ShowDeviceAdvancedInfo(const DeviceIndex: Integer);

  procedure AddRow(ACaption, AData: String; const GroupID: Byte);
  begin
    if AData <> '' then
      ListView_AddItemsInGroup(lvAdvancedInfo, ACaption, AData, GroupID);
  end;

var
  DeviceInfoData: SP_DEVINFO_DATA;
  EmptyGUID, AGUID: TGUID;
  dwData: DWORD;
begin
  ZeroMemory(@EmptyGUID, SizeOf(TGUID));
  // �������������� ��������� ��� ��������� ����������
  ZeroMemory(@DeviceInfoData, SizeOf(SP_DEVINFO_DATA));
  DeviceInfoData.cbSize := SizeOf(SP_DEVINFO_DATA);

  // �������� ������ �� ����������
  if not SetupDiEnumDeviceInfo(hAllDevices,
    DeviceIndex, DeviceInfoData) then Exit;

  // �������������� ��� DeviceHelper,
  // ���������� ������ � SP_DEVINFO_DATA ����� �����������
  // ��� ������ ������� ������� ������
  DeviceHelper.DeviceInfoData := DeviceInfoData;

  ListView_EnableGroupView(lvAdvancedInfo.Handle, True);
  ListView_InsertGroup(lvAdvancedInfo.Handle, 'SP_DEVINFO_DATA', 0);

  // ������� ��� ������ ������� ����� ��������
  AddRow('Device Descriptiion', DeviceHelper.Description, 0);
  AddRow('Hardware IDs', DeviceHelper.HardwareID, 0);
  AddRow('Compatible IDs', DeviceHelper.CompatibleIDS, 0);
  AddRow('Driver', DeviceHelper.DriverName, 0);
  AddRow('Class name', DeviceHelper.DeviceClassName, 0);
  AddRow('Manufacturer', DeviceHelper.Manufacturer, 0);
  AddRow('Friendly Description', DeviceHelper.FriendlyName, 0);
  AddRow('Location Information', DeviceHelper.Location, 0);
  AddRow('Device CreateFile Name', DeviceHelper.PhisicalDriverName, 0);
  AddRow('Capabilities', DeviceHelper.Capabilities, 0);
  AddRow('Service', DeviceHelper.Service, 0);
  AddRow('ConfigFlags', DeviceHelper.ConfigFlags, 0);
  AddRow('UpperFilters', DeviceHelper.UpperFilters, 0);
  AddRow('LowerFilters', DeviceHelper.LowerFilters, 0);
  AddRow('LegacyBusType', DeviceHelper.LegacyBusType, 0);
  AddRow('Enumerator', DeviceHelper.Enumerator, 0);
  AddRow('Characteristics', DeviceHelper.Characteristics, 0);
  AddRow('UINumberDecription', DeviceHelper.UINumberDecription, 0);
  AddRow('PowerData', DeviceHelper.PowerData, 0);
  AddRow('RemovalPolicy', DeviceHelper.RemovalPolicy, 0);
  AddRow('RemovalPolicyHWDefault', DeviceHelper.RemovalPolicyHWDefault, 0);
  AddRow('RemovalPolicyOverride', DeviceHelper.RemovalPolicyOverride, 0);
  AddRow('InstallState', DeviceHelper.InstallState, 0);

  if not CompareMem(@EmptyGUID, @DeviceInfoData.ClassGUID,
    SizeOf(TGUID)) then
    AddRow('Device GUID', GUIDToString(DeviceInfoData.ClassGUID), 0);

  AGUID := DeviceHelper.BusTypeGUID;
  if not CompareMem(@EmptyGUID, @AGUID,
    SizeOf(TGUID)) then
    AddRow('Bus Type GUID', GUIDToString(AGUID), 0);

  dwData := DeviceHelper.UINumber;
  if dwData <> 0 then
    AddRow('UI Number', IntToStr(dwData), 0);

  dwData := DeviceHelper.BusNumber;
  if dwData <> 0 then
    AddRow('Bus Number', IntToStr(dwData), 0);

  dwData := DeviceHelper.Address;
  if dwData <> 0 then
    AddRow('Device Address', IntToStr(dwData), 0);

//  dwData := DeviceHelper.Security;
//  if dwData <> 0 then
//    AddRow('Security', IntToStr(dwData), 0);
//  AddRow('Device Type', DeviceHelper.DeviceType, 0);
//  AddRow('Exclusive', DeviceHelper.Exclusive, 0);
//  AddRow('SecuritySDS', DeviceHelper.SecuritySDS, 0);

  lvAdvancedInfo.AlphaSort;

end;

procedure TdlgMain.ShowDeviceInterfaces(const DeviceIndex: Integer);

  procedure AddRow(ACaption, AData: String; const GroupID: Byte);
  begin
    if AData <> '' then
      ListView_AddItemsInGroup(lvAdvancedInfo, ACaption, AData, GroupID);
  end;

var
  hInterfaces: HDEVINFO;
  DeviceInfoData: SP_DEVINFO_DATA;
  DeviceInterfaceData: TSPDeviceInterfaceData;
  I: Integer;
begin
  ListView_InsertGroup(lvAdvancedInfo.Handle, 'Interfaces Data', 1);

  // �������������� ��������� ��� ��������� ����������
  ZeroMemory(@DeviceInfoData, SizeOf(SP_DEVINFO_DATA));
  DeviceInfoData.cbSize := SizeOf(SP_DEVINFO_DATA);

  ZeroMemory(@DeviceInterfaceData, SizeOf(TSPDeviceInterfaceData));
  DeviceInterfaceData.cbSize := SizeOf(TSPDeviceInterfaceData);

  // �������� ������ �� ����������
  if not SetupDiEnumDeviceInfo(hAllDevices,
    DeviceIndex, DeviceInfoData) then Exit;

  hInterfaces := SetupDiGetClassDevs(@DeviceInfoData.ClassGuid, nil, 0,
    DIGCF_PRESENT or DIGCF_INTERFACEDEVICE);
  if not Assigned(hInterfaces) then
      RaiseLastOSError;
  try
    I := 0;
    while SetupDiEnumDeviceInterfaces(hInterfaces, nil,
      DeviceInfoData.ClassGuid, I, DeviceInterfaceData) do
    begin
      case DeviceInterfaceData.Flags of
        SPINT_ACTIVE:
          AddRow('Interface State', 'SPINT_ACTIVE', 1);
        SPINT_DEFAULT:
          AddRow('Interface State', 'SPINT_DEFAULT', 1);
        SPINT_REMOVED:
          AddRow('Interface State', 'SPINT_REMOVED', 1);
      else
        AddRow('Interface State', 'unknown 0x' +
          IntToHex(DeviceInterfaceData.Flags, 8), 1);
      end;
      Inc(I);
    end;

  finally
    SetupDiDestroyDeviceInfoList(hInterfaces);
  end;

  AddRow('qwe', IntToStr(DeviceInterfaceData.Flags), 1);
end;

procedure TdlgMain.tvDevicesChange(Sender: TObject; Node: TTreeNode);
var
  ANode: TTreeNode;
begin
  lvAdvancedInfo.Items.BeginUpdate;
  try
    lvAdvancedInfo.Items.Clear;
    ANode := tvDevices.Selected;
    if Assigned(ANode) then
    begin
      if ANode.StateIndex >= 0 then
      begin
        ShowDeviceAdvancedInfo(ANode.StateIndex);
        ShowDeviceInterfaces(ANode.StateIndex);
        ANode := ANode.Parent;
      end;
      StatusBar.Panels[2].Text :=
        Format('Devices Count in DeviceClass "%s": %d',
          [ANode.Text, ANode.Count]);
    end;
  finally
    lvAdvancedInfo.Items.EndUpdate;
  end;
end;

procedure TdlgMain.tvDevicesCompare(Sender: TObject; Node1, Node2: TTreeNode;
  Data: Integer; var Compare: Integer);
begin
  Compare := CompareText(Node1.Text, Node2.Text);
end;

end.
