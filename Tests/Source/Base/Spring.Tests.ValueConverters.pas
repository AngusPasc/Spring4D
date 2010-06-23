{***************************************************************************}
{                                                                           }
{           Spring Framework for Delphi                                     }
{                                                                           }
{           Copyright (C) 2009-2010 DevJet                                  }
{                                                                           }
{           http://www.DevJet.net                                           }
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

unit Spring.Tests.ValueConverters;

interface

uses
  SysUtils,
  TestFramework,
  TestExtensions,
  Rtti,
  Spring.ValueConverters;

type
  TTestValueConverters = class(TTestCase)
  private
    fConverter: IValueConverter;
    type
      TEnumeration = (teFirst, teSecond, teLast);
  protected
    procedure SetUp; override;
  published
    procedure TestIntegerToString;
    procedure TestStringToInteger;
    procedure TestEnumToString;
    procedure TestEnumToInteger;
    procedure TestIntegerToEnum;
    procedure TestStringToEnum;
    procedure TestIntegerToBoolean;
    procedure TestBooleanToInteger;
    procedure TestStringToBoolean;
    procedure TestBooleanToString;
    procedure TestNullableIntegerToInteger;
    procedure TestNullableIntegerToString;
    procedure TestNullableFloatToString;
    procedure TestNullableStringToFloat;
    procedure TestNullableDateTimeToString;
    procedure TestNullableColorToString;
    procedure TestStringToNullableString;
    procedure TestStringToNullableInteger;
    procedure TestStringToNullableExtended;
    procedure TestExtendedToNullableString;
    procedure TestStringToNullableDateTime;
    procedure TestStringToNullableColor;
    procedure TestStringToFloat;
    procedure TestFloatToString;
    procedure TestStringToColor;
    procedure TestColorToString;
    procedure TestStringToCurrency;
    procedure TestCurrencyToString;
    procedure TestStringToDateTime;
    procedure TestDateTimeToString;
  end;

implementation

uses
  Graphics,
  DateUtils,
  Spring;

{$REGION 'TTestValueConverters'}

procedure TTestValueConverters.SetUp;
begin
  inherited;
  fConverter := TValueConverter.Default;
end;

procedure TTestValueConverters.TestBooleanToInteger;
var
  outValue: TValue;
  outInt: Integer;
begin
  outValue := fConverter.ConvertTo(TValue.From<Boolean>(False),
    TypeInfo(Integer));
  CheckFalse(outValue.IsEmpty);
  CheckTrue(outValue.TryAsType<Integer>(outInt));
  CheckEquals(outInt, 0);
end;

procedure TTestValueConverters.TestBooleanToString;
var
  outValue: TValue;
  outStr: string;
begin
  outValue := fConverter.ConvertTo(TValue.From<Boolean>(False),
    TypeInfo(string));
  CheckFalse(outValue.IsEmpty);
  CheckTrue(outValue.TryAsType<string>(outStr));
  CheckEqualsString(outStr, 'False');
end;

procedure TTestValueConverters.TestColorToString;
var
  outValue: TValue;
  outStr: string;
begin
  outValue := fConverter.ConvertTo(TValue.From<TColor>(clRed),
    TypeInfo(string));
  CheckFalse(outValue.IsEmpty);
  CheckTrue(outValue.TryAsType<string>(outStr));
  CheckEqualsString(outStr, 'clRed');
end;

procedure TTestValueConverters.TestCurrencyToString;
var
  outValue: TValue;
  outStr: string;
begin
  outValue := fConverter.ConvertTo(TValue.From<Currency>(1.11),
    TypeInfo(string));
  CheckFalse(outValue.IsEmpty);
  CheckTrue(outValue.TryAsType<string>(outStr));
  CheckEqualsString(outStr, FloatToStr(1.11));
end;

procedure TTestValueConverters.TestDateTimeToString;
var
  outValue: TValue;
  outStr: string;
  stamp: TDateTime;
begin
  stamp := Now;
  outValue := fConverter.ConvertTo(TValue.From<TDateTime>(stamp),
    TypeInfo(string));
  CheckFalse(outValue.IsEmpty);
  CheckTrue(outValue.TryAsType<string>(outStr));
  CheckEqualsString(outStr, DateTimeToStr(stamp));
end;

procedure TTestValueConverters.TestIntegerToBoolean;
var
  outValue: TValue;
  outBool: Boolean;
begin
  outValue := fConverter.ConvertTo(TValue.From<Integer>(1),
    TypeInfo(Boolean));
  CheckFalse(outValue.IsEmpty);
  CheckTrue(outValue.TryAsType<Boolean>(outBool));
  CheckEquals(outBool, True);
end;

procedure TTestValueConverters.TestStringToBoolean;
var
  outValue: TValue;
  outBool: Boolean;
begin
  outValue := fConverter.ConvertTo(TValue.From<string>('False'),
    TypeInfo(Boolean));
  CheckFalse(outValue.IsEmpty);
  CheckTrue(outValue.TryAsType<Boolean>(outBool));
  CheckEquals(outBool, False);
end;

procedure TTestValueConverters.TestStringToColor;
var
  outValue: TValue;
  outColor: TColor;
begin
  outValue := fConverter.ConvertTo(TValue.From<string>('clBlue'),
    TypeInfo(TColor));
  CheckFalse(outValue.IsEmpty);
  CheckTrue(outValue.TryAsType<TColor>(outColor));
  CheckEquals(outColor, clBlue);
end;

procedure TTestValueConverters.TestStringToCurrency;
var
  outValue: TValue;
  outCurrency: Currency;
begin
  outValue := fConverter.ConvertTo(TValue.From<string>(FloatToStr(1.11)),
    TypeInfo(Currency));
  CheckFalse(outValue.IsEmpty);
  CheckTrue(outValue.TryAsType<Currency>(outCurrency));
  CheckEquals(outCurrency, 1.11);
end;

procedure TTestValueConverters.TestStringToDateTime;
var
  outValue: TValue;
  outStamp: TDateTime;
  stamp: TDateTime;
begin
  stamp := Now;
  outValue := fConverter.ConvertTo(TValue.From<string>(DateTimeToStr(stamp)),
    TypeInfo(TDateTime));
  CheckFalse(outValue.IsEmpty);
  CheckTrue(outValue.TryAsType<TDateTime>(outStamp));
  CheckTrue(SameDateTime(outStamp, stamp));
end;

procedure TTestValueConverters.TestEnumToInteger;
var
  outValue: TValue;
  outInt: Integer;
begin
  outValue := fConverter.ConvertTo(TValue.From<TEnumeration>(teSecond),
    TypeInfo(Integer));
  CheckFalse(outValue.IsEmpty);
  CheckTrue(outValue.TryAsType<Integer>(outInt));
  CheckEquals(outInt, 1);
end;

procedure TTestValueConverters.TestEnumToString;
var
  outValue: TValue;
  outStr: string;
begin
  outValue := fConverter.ConvertTo(TValue.From<TEnumeration>(teFirst),
    TypeInfo(string));
  CheckFalse(outValue.IsEmpty);
  CheckTrue(outValue.TryAsType<string>(outStr));
  CheckEquals(outStr, 'teFirst');
end;

procedure TTestValueConverters.TestExtendedToNullableString;
var
  outValue: TValue;
  outNullable: TNullable<string>;
begin
  outValue := fConverter.ConvertTo(TValue.From<Extended>(1.11),
    TypeInfo(TNullable<string>));
  CheckFalse(outValue.IsEmpty);
  CheckTrue(outValue.TryAsType<TNullable<string>>(outNullable));
  CheckEquals(outNullable.Value, FloatToStr(1.11));
end;

procedure TTestValueConverters.TestFloatToString;
var
  outValue: TValue;
  outStr: string;
begin
  outValue := fConverter.ConvertTo(TValue.From<Extended>(1.11),
    TypeInfo(string));
  CheckFalse(outValue.IsEmpty);
  CheckTrue(outValue.TryAsType<string>(outStr));
  CheckEquals(outStr, FloatToStr(1.11));
end;

procedure TTestValueConverters.TestIntegerToEnum;
var
  outValue: TValue;
  outEnum: TEnumeration;
begin
  outValue := fConverter.ConvertTo(TValue.From<Integer>(1),
    TypeInfo(TEnumeration));
  CheckFalse(outValue.IsEmpty);
  CheckTrue(outValue.TryAsType<TEnumeration>(outEnum));
  CheckTrue(outEnum = teSecond);
end;

procedure TTestValueConverters.TestStringToEnum;
var
  outValue: TValue;
  outEnum: TEnumeration;
begin
  outValue := fConverter.ConvertTo(TValue.From<string>('teLast'),
    TypeInfo(TEnumeration));
  CheckFalse(outValue.IsEmpty);
  CheckTrue(outValue.TryAsType<TEnumeration>(outEnum));
  CheckTrue(outEnum = teLast);
end;

procedure TTestValueConverters.TestStringToFloat;
var
  outValue: TValue;
  outFloat: Extended;
begin
  outValue := fConverter.ConvertTo(TValue.From<string>(FloatToStr(1.11)),
    TypeInfo(Extended));
  CheckFalse(outValue.IsEmpty);
  CheckTrue(outValue.TryAsType<Extended>(outFloat));
  CheckEquals(outFloat, 1.11);
end;

procedure TTestValueConverters.TestIntegerToString;
var
  outValue: TValue;
  outStr: string;
begin
  outValue := fConverter.ConvertTo(TValue.From<Integer>(1),
    TypeInfo(string));
  CheckFalse(outValue.IsEmpty);
  CheckTrue(outValue.TryAsType<string>(outStr));
  CheckEquals(outValue.AsString, '1');
end;

procedure TTestValueConverters.TestStringToInteger;
var
  outValue: TValue;
  outInt: Integer;
begin
  outValue := fConverter.ConvertTo(TValue.From<string>('1'),
    TypeInfo(Integer));
  CheckFalse(outValue.IsEmpty);
  CheckTrue(outValue.TryAsType<Integer>(outInt));
  CheckEquals(outValue.AsInteger, 1);
end;

procedure TTestValueConverters.TestNullableColorToString;
var
  outValue: TValue;
  outStr: string;
begin
  outValue := fConverter.ConvertTo(TValue.From<TNullable<TColor>>(TNullable<TColor>.Create(clRed)),
    TypeInfo(string));
  CheckFalse(outValue.IsEmpty);
  CheckTrue(outValue.TryAsType<string>(outStr));
  CheckEquals(outStr, 'clRed');
end;

procedure TTestValueConverters.TestNullableDateTimeToString;
var
  outValue: TValue;
  outStr: string;
  stamp: TDateTime;
begin
  stamp := Now;
  outValue := fConverter.ConvertTo(TValue.From<TNullable<TDateTime>>(TNullable<TDateTime>.Create(stamp)),
    TypeInfo(string));
  CheckFalse(outValue.IsEmpty);
  CheckTrue(outValue.TryAsType<string>(outStr));
  CheckEquals(outStr, DateTimeToStr(stamp));
end;

procedure TTestValueConverters.TestNullableFloatToString;
var
  outValue: TValue;
  outStr: string;
begin
  outValue := fConverter.ConvertTo(TValue.From<TNullable<Extended>>(TNullable<Extended>.Create(1.11)),
    TypeInfo(string));
  CheckFalse(outValue.IsEmpty);
  CheckTrue(outValue.TryAsType<string>(outStr));
  CheckEquals(outStr, FloatToStr(1.11));
end;

procedure TTestValueConverters.TestNullableIntegerToInteger;
var
  outValue: TValue;
  outInt: Integer;
begin
  outValue := fConverter.ConvertTo(TValue.From<TNullable<Integer>>(TNullable<Integer>.Create(1)),
    TypeInfo(Integer));
  CheckFalse(outValue.IsEmpty);
  CheckTrue(outValue.TryAsType<Integer>(outInt));
  CheckEquals(outInt, 1);
end;

procedure TTestValueConverters.TestNullableIntegerToString;
var
  outValue: TValue;
  outStr: string;
begin
  outValue := fConverter.ConvertTo(TValue.From<TNullable<Integer>>(TNullable<Integer>.Create(1)),
    TypeInfo(string));
  CheckFalse(outValue.IsEmpty);
  CheckTrue(outValue.TryAsType<string>(outStr));
  CheckEquals(outStr, '1');
end;

procedure TTestValueConverters.TestNullableStringToFloat;
var
  outValue: TValue;
  outFloat: Extended;
begin
  outValue := fConverter.ConvertTo(TValue.From<TNullable<string>>(TNullable<string>.Create(FloatToStr(1.11))),
    TypeInfo(Extended));
  CheckFalse(outValue.IsEmpty);
  CheckTrue(outValue.TryAsType<Extended>(outFloat));
  CheckEquals(outFloat, 1.11);
end;

procedure TTestValueConverters.TestStringToNullableColor;
var
  outValue: TValue;
  outNullable: TNullable<TColor>;
begin
  outValue := fConverter.ConvertTo(TValue.From<string>(ColorToString(clRed)),
    TypeInfo(TNullable<TColor>));
  CheckFalse(outValue.IsEmpty);
  CheckTrue(outValue.TryAsType<TNullable<TColor>>(outNullable));
  CheckEquals(ColorToString(outNullable.Value), 'clRed');
end;

procedure TTestValueConverters.TestStringToNullableDateTime;
var
  outValue: TValue;
  outNullable: TNullable<TDateTime>;
  stamp: TDateTime;
begin
  stamp := Now;
  outValue := fConverter.ConvertTo(TValue.From<string>(DateTimeToStr(stamp)),
    TypeInfo(TNullable<TDateTime>));
  CheckFalse(outValue.IsEmpty);
  CheckTrue(outValue.TryAsType<TNullable<TDateTime>>(outNullable));
  CheckTrue(SameDateTime(outNullable.Value, stamp));
end;

procedure TTestValueConverters.TestStringToNullableExtended;
var
  outValue: TValue;
  outNullable: TNullable<Extended>;
begin
  outValue := fConverter.ConvertTo(TValue.From<string>(FloatToStr(1.11)),
    TypeInfo(TNullable<Extended>));
  CheckFalse(outValue.IsEmpty);
  CheckTrue(outValue.TryAsType<TNullable<Extended>>(outNullable));
  CheckEquals(outNullable.Value, 1.11);
end;

procedure TTestValueConverters.TestStringToNullableInteger;
var
  outValue: TValue;
  outNullable: TNullable<Integer>;
begin
  outValue := fConverter.ConvertTo(TValue.From<string>('15'),
    TypeInfo(TNullable<Integer>));
  CheckFalse(outValue.IsEmpty);
  CheckTrue(outValue.TryAsType<TNullable<Integer>>(outNullable));
  CheckTrue(outNullable.HasValue);
  CheckEquals(outNullable.Value, 15);
end;

procedure TTestValueConverters.TestStringToNullableString;
var
  outValue: TValue;
  outNullable: TNullable<string>;
begin
  outValue := fConverter.ConvertTo(TValue.From<string>('0'),
    TypeInfo(TNullable<string>));
  CheckFalse(outValue.IsEmpty);
  CheckTrue(outValue.TryAsType<TNullable<string>>(outNullable));
  CheckTrue(outNullable.HasValue);
  CheckEquals(outNullable.Value, '0');
end;

{$ENDREGION}

end.
