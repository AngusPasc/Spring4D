{***************************************************************************}
{                                                                           }
{               Delphi Spring Framework                                     }
{                                                                           }
{               Copyright (C) 2008-2009 Zuo Baoquan                         }
{                                                                           }
{               http://www.zuobaoquan.com (Simplified Chinese)              }
{                                                                           }
{***************************************************************************}
{                                                                           }
{  Licensed under the Apache License, Version 2.0 (the "License");          }
{  you may not use this file except in compliance with the License.         }
{  You may obtain a copy of the License at                                  }
{                                                                           }
{      http://www.apache.org/licenses/LICENSE-2.0                           }
{                                                                           }
{  Unless required by applicable law or agreed to in writing, software      }
{  distributed under the License is distributed on an "AS IS" BASIS,        }
{  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. }
{  See the License for the specific language governing permissions and      }
{  limitations under the License.                                           }
{                                                                           }
{***************************************************************************}

{TODO -oOwner -cGeneral : TRectHelper}
{TODO -oOwner -cGeneral : TSizeHelper}
{TODO -oOwner -cGeneral : TPointHelper}

unit Spring.Helpers;

{$I Spring.inc}

interface

uses
  Classes, Types, SysUtils, ComObj, Spring.Patterns;

type
  /// <summary>
  /// TGuid record helper
  /// </summary>
  TGuidHelper = record helper for TGuid
  private
    class function GetEmpty: TGuid; static;
    function GetIsEmpty: Boolean;
  public
    class function Create(const guidString: string): TGuid; static;
    class function NewGuid: TGuid; static;
    function Equals(const guid: TGuid): Boolean;
    function ToString: string;
    function ToQuotedString: string;
    property IsEmpty: Boolean read GetIsEmpty;
    class property Empty: TGuid read GetEmpty;
  end;

  TMethodHelper = record helper for TMethod
  public
    class function Create(const objectAddress, methodAddress: Pointer): TMethod; static;
  end;

  ISnapshot = Spring.Patterns.ISnapshot;

  TPersistentSnapshot = class(TInterfacedObject, ISnapshot, IInterface)
  private
    fSnapshot: TPersistent;
  protected
    property Snapshot: TPersistent read fSnapshot;
  public
    constructor Create(snapshot: TPersistent);
    destructor Destroy; override;
  end;

  TPersistentHelper = class helper for TPersistent
  public
    function CreateSnapshot<T: TPersistent, constructor>: ISnapshot;
    procedure Restore(const snapshot: ISnapshot);
  end;

  (*
  /// <summary>
  /// TRectHelper
  /// </summary>
  TRectHelper = record helper for TRect

  end;
  //*)

implementation


{$IFDEF SUPPORTS_REGION} {$REGION 'TGuidHelper'} {$ENDIF}

class function TGuidHelper.Create(const guidString: string): TGuid;
begin
  Result := StringToGUID(guidString);
end;

class function TGuidHelper.NewGuid: TGuid;
begin
  ComObj.OleCheck(SysUtils.CreateGUID(Result));
end;

function TGuidHelper.Equals(const guid: TGuid): Boolean;
begin
  Result := SysUtils.IsEqualGUID(Self, guid);
end;

function TGuidHelper.GetIsEmpty: Boolean;
begin
  Result := Self.Equals(TGuid.Empty);
end;

function TGuidHelper.ToString: string;
begin
  Result := SysUtils.GUIDToString(Self);
end;

function TGuidHelper.ToQuotedString: string;
begin
  Result := QuotedStr(Self.ToString);
end;

class function TGuidHelper.GetEmpty: TGuid;
const
  EmptyGuid: TGUID = (
    D1: 0;
    D2: 0;
    D3: 0;
    D4: (0, 0, 0, 0, 0, 0, 0, 0);
  );
begin
  Result := EmptyGuid;
end;

//class operator TGuidHelper.Equal(const left, right: TGuid) : Boolean;
//begin
//  Result := left.Equals(right);
//end;
//
//class operator TGuidHelper.NotEqual(const left, right: TGuid) : Boolean;
//begin
//  Result := not left.Equals(right);
//end;

{$IFDEF SUPPORTS_REGION} {$ENDREGION} {$ENDIF}


{$IFDEF SUPPORTS_REGION} {$REGION 'TMethodHelper'} {$ENDIF}

class function TMethodHelper.Create(const objectAddress,
  methodAddress: Pointer): TMethod;
begin
  Result.Code := methodAddress;
  Result.Data := objectAddress;
end;

{$IFDEF SUPPORTS_REGION} {$ENDREGION} {$ENDIF}


{$IFDEF SUPPORTS_REGION} {$REGION 'TPersistentSnapshot'} {$ENDIF}

constructor TPersistentSnapshot.Create(snapshot: TPersistent);
begin
  inherited Create;
  fSnapshot := snapshot;
end;

destructor TPersistentSnapshot.Destroy;
begin
  fSnapshot.Free;
  inherited Destroy;
end;

{$IFDEF SUPPORTS_REGION} {$ENDREGION} {$ENDIF}


{$IFDEF SUPPORTS_REGION} {$REGION 'TPersistentHelper'} {$ENDIF}

function TPersistentHelper.CreateSnapshot<T>: ISnapshot;
var
  storage: T;
begin
  storage := T.Create;
  try
    storage.Assign(Self);
  except
    storage.Free;
    raise;
  end;
  Result := TPersistentSnapshot.Create(storage);
end;

procedure TPersistentHelper.Restore(const snapshot: ISnapshot);
begin
  if snapshot is TPersistentSnapshot then
  begin
    Assign(TPersistentSnapshot(snapshot).Snapshot);
  end;
end;

{$IFDEF SUPPORTS_REGION} {$ENDREGION} {$ENDIF}

end.