{***************************************************************************}
{                                                                           }
{           Spring Framework for Delphi                                     }
{                                                                           }
{           Copyright (C) 2009-2011 DevJET                                  }
{                                                                           }
{           http://www.DevJET.net                                           }
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

unit Spring.Cryptography.Core;

interface

{$I Spring.inc}

uses
  Classes,
  SysUtils,
  Spring,
  Spring.Cryptography;

type
  /// <summary>
  /// Abstract base class for hash algorithms.
  /// </summary>
  THashAlgorithmBase = class abstract(TInterfacedObject, IHashAlgorithm, IInterface)
  protected
    fHash: TBuffer;
//    fState: Integer;
  protected
    procedure HashInit; virtual; abstract;
    procedure HashUpdate(const buffer: Pointer; count: Integer); virtual; abstract;
    function HashFinal: TBuffer; virtual; abstract;
    function GetHashSize: Integer; virtual; abstract;
    property Hash: TBuffer read fHash;
  public
    function ComputeHash(const buffer: array of Byte): TBuffer; overload;
    function ComputeHash(const buffer: array of Byte; startIndex, count: Integer): TBuffer; overload;
    function ComputeHash(const buffer: Pointer; count: Integer): TBuffer; overload;
    function ComputeHash(const inputString: string): TBuffer; overload;
    function ComputeHash(const inputString: WideString): TBuffer; overload;
    function ComputeHash(const inputString: RawByteString): TBuffer; overload;
    function ComputeHash(const inputStream: TStream): TBuffer; overload; virtual;
    function ComputeHashOfFile(const fileName: string): TBuffer; virtual;
    property HashSize: Integer read GetHashSize;
  end;

  {TODO -oPaul -cGeneral : Refactoring: EncryptBlock/EncryptFinalBlock/Decrypt***}
  {TODO 5 -oPaul -cGeneral : BUG FIXES: TSymmetricAlgorithmBase.Encrypt/Decrypt(inputStream, outputStream)}

  /// <summary>
  /// Abstract base class for symmetric algorithms.
  /// </summary>
  TSymmetricAlgorithmBase = class abstract(TInterfacedObject, ISymmetricAlgorithm)
  private
    fCipherMode: TCipherMode;
    fPaddingMode: TPaddingMode;
    fLegalBlockSizes: TSizes;
    fLegalKeySizes: TSizes;
    fBlockSize: Integer;
    fKeySize: Integer;
    fKey: TBuffer;
    fIV: TBuffer;
    function GetBlockSizeInBytes: Integer;
    function GetKeySizeInBytes: Integer;
  protected
    function GetBlockSize: Integer; virtual;
    function GetKeySize: Integer; virtual;
    function GetLegalBlockSizes: TSizes; virtual;
    function GetLegalKeySizes: TSizes; virtual;
    function GetCipherMode: TCipherMode; virtual;
    function GetPaddingMode: TPaddingMode; virtual;
    function GetKey: TBuffer; virtual;
    function GetIV: TBuffer; virtual;
    procedure SetBlockSize(const value: Integer); virtual;
    procedure SetKeySize(const value: Integer); virtual;
    procedure SetPaddingMode(const value: TPaddingMode); virtual;
    procedure SetCipherMode(const value: TCipherMode); virtual;
    procedure SetKey(const value: TBuffer); virtual;
    procedure SetIV(const value: TBuffer); virtual;
  protected
    procedure AddPadding(var buffer: TBuffer; startIndex: Integer; count: Integer);
    procedure RemovePadding(var buffer: TBuffer);
    procedure ValidateKey(const key: TBuffer); virtual;
    function GenerateIV: TBuffer; virtual;
    function GenerateKey: TBuffer; virtual;
    property BlockSizeInBytes: Integer read GetBlockSizeInBytes;
    property KeySizeInBytes: Integer read GetKeySizeInBytes;
  protected
    procedure DoEncryptBlock(const inputBuffer: TBytes; var outputBuffer: TBytes); virtual; abstract;
    procedure DoDecryptBlock(const inputBuffer: TBytes; var outputBuffer: TBytes); virtual; abstract;
    function DoEncrypt(const buffer: Pointer; count: Integer): TBuffer; virtual;
    function DoDecrypt(const buffer: Pointer; count: Integer): TBuffer; virtual;
  public
    constructor Create(const legalBlockSizes, legalKeySizes: array of Integer);
    function Encrypt(const buffer: Pointer; count: Integer): TBuffer; overload;
    function Encrypt(const buffer: TBuffer): TBuffer; overload;
    function Encrypt(const buffer: array of Byte): TBuffer; overload;
    function Encrypt(const buffer: array of Byte; startIndex, count: Integer): TBuffer; overload;
    function Encrypt(const inputString: string): TBuffer; overload;
    function Encrypt(const inputString: WideString): TBuffer; overload;
    function Encrypt(const inputString: RawByteString): TBuffer; overload;
    procedure Encrypt(inputStream, outputStream: TStream); overload;
    function Decrypt(const buffer: Pointer; count: Integer): TBuffer; overload;
    function Decrypt(const buffer: TBuffer): TBuffer; overload;
    function Decrypt(const buffer: array of Byte): TBuffer; overload;
    function Decrypt(const buffer: array of Byte; startIndex, count: Integer): TBuffer; overload;
    function Decrypt(const inputString: string): TBuffer; overload;
    function Decrypt(const inputString: WideString): TBuffer; overload;
    function Decrypt(const inputString: RawByteString): TBuffer; overload;
    procedure Decrypt(inputStream, outputStream: TStream); overload;
    property CipherMode: TCipherMode read GetCipherMode write SetCipherMode;
    property PaddingMode: TPaddingMode read GetPaddingMode write SetPaddingMode;
    property Key: TBuffer read GetKey write SetKey;
    property IV: TBuffer read GetIV write SetIV;
    property BlockSize: Integer read GetBlockSize write SetBlockSize;
    property KeySize: Integer read GetKeySize write SetKeySize;
    property LegalBlockSizes: TSizes read GetLegalBlockSizes;
    property LegalKeySizes: TSizes read GetLegalKeySizes;
  end;

  /// <summary>
  /// TRandomNumberGenerator
  /// </summary>
  TRandomNumberGenerator = class(TInterfacedObject, IRandomNumberGenerator)
  public
    procedure GetBytes(var data: TBytes);
    procedure GetNonZeroBytes(var data: TBytes);
  end;

  {$ENDREGION}

implementation

uses
  Math,
  Spring.Utils,
  Spring.ResourceStrings;

{$REGION 'THashAlgorithmBase'}

function THashAlgorithmBase.ComputeHash(const buffer: Pointer;
  count: Integer): TBuffer;
begin
  HashInit;
  HashUpdate(buffer, count);
  fHash := HashFinal;
  Result := fHash;
end;

function THashAlgorithmBase.ComputeHash(const buffer: array of Byte): TBuffer;
begin
  Result := ComputeHash(@buffer[0], Length(buffer));
end;

function THashAlgorithmBase.ComputeHash(const buffer: array of Byte; startIndex,
  count: Integer): TBuffer;
begin
  TArgument.CheckRange(buffer, startIndex, count);
  Result := ComputeHash(@buffer[startIndex], count);
end;

function THashAlgorithmBase.ComputeHash(const inputString: string): TBuffer;
begin
  Result := ComputeHash(PByte(inputString), Length(inputString) * SizeOf(Char));
end;

function THashAlgorithmBase.ComputeHash(const inputString: WideString): TBuffer;
begin
  Result := ComputeHash(PByte(inputString), Length(inputString) * SizeOf(Char));
end;

function THashAlgorithmBase.ComputeHash(
  const inputString: RawByteString): TBuffer;
begin
  Result := ComputeHash(PByte(inputString), Length(inputString));
end;

function THashAlgorithmBase.ComputeHash(const inputStream: TStream): TBuffer;
var
  buffer: array[0..512-1] of Byte;
  count: Integer;
begin
  TArgument.CheckNotNull(inputStream, 'inputStream');
  HashInit;
  count := inputStream.Read(buffer[0], Length(buffer));
  while count > 0 do
  begin
    HashUpdate(@buffer[0], count);
    count := inputStream.Read(buffer[0], Length(buffer));
  end;
  fHash := HashFinal;
  Result := fHash;
end;

function THashAlgorithmBase.ComputeHashOfFile(const fileName: string): TBuffer;
var
  stream: TStream;
begin
  stream := TFileStream.Create(fileName, fmOpenRead or fmShareExclusive);
  try
    Result := ComputeHash(stream);
  finally
    stream.Free;
  end;
end;

{$ENDREGION}


{$REGION 'TSymmetricAlgorithmBase'}

constructor TSymmetricAlgorithmBase.Create(
  const legalBlockSizes, legalKeySizes: array of Integer);
begin
  inherited Create;
  fLegalBlockSizes := TSizes.Create(legalBlockSizes);
  fLegalKeySizes := TSizes.Create(legalKeySizes);
  fCipherMode := cmCBC;
  fPaddingMode := pmPKCS7;
end;

procedure TSymmetricAlgorithmBase.ValidateKey(const key: TBuffer);
var
  sizes: TSizes;
begin
  sizes := fLegalKeySizes;
  if not sizes.Contains(key.Size * 8) then
  begin
    raise ECryptographicException.CreateResFmt(@SIllegalKeySize, [key.Size]);
  end;
end;

function TSymmetricAlgorithmBase.Encrypt(const buffer: TBuffer): TBuffer;
begin
  Result := Encrypt(buffer.Memory, buffer.Size);
end;

function TSymmetricAlgorithmBase.Encrypt(const buffer: array of Byte): TBuffer;
begin
  Result := Encrypt(@buffer[0], Length(buffer));
end;

function TSymmetricAlgorithmBase.Encrypt(const buffer: array of Byte;
  startIndex, count: Integer): TBuffer;
begin
  TArgument.CheckRange(buffer, startIndex, count);
  Result := Encrypt(@buffer[startIndex], count);
end;

function TSymmetricAlgorithmBase.Encrypt(const buffer: Pointer;
  count: Integer): TBuffer;
begin
  Result := DoEncrypt(buffer, count);
end;

function TSymmetricAlgorithmBase.Encrypt(const inputString: string): TBuffer;
begin
  Result := Encrypt(PByte(inputString), Length(inputString) * SizeOf(Char));
end;

function TSymmetricAlgorithmBase.Encrypt(
  const inputString: WideString): TBuffer;
begin
  Result := Encrypt(PByte(inputString), Length(inputString) * SizeOf(Char));
end;

function TSymmetricAlgorithmBase.Encrypt(
  const inputString: RawByteString): TBuffer;
begin
  Result := Encrypt(PByte(inputString), Length(inputString));
end;

procedure TSymmetricAlgorithmBase.Encrypt(inputStream, outputStream: TStream);
var
  inputBuffer: TBuffer;
  outputBuffer: TBuffer;
  bytes: Integer;
begin
  TArgument.CheckNotNull(inputStream, 'inputStream');
  TArgument.CheckNotNull(outputStream, 'outputStream');
  inputBuffer.Size := BlockSizeInBytes;
  outputBuffer.Size := BlockSizeInBytes;
  bytes := inputStream.Read(inputBuffer.Memory^, inputBuffer.Size);
  while bytes > 0 do
  begin
    outputBuffer := Encrypt(inputBuffer);
    outputStream.WriteBuffer(outputBuffer.Memory^, outputBuffer.Size);
    bytes := inputStream.Read(inputBuffer.Memory^, inputBuffer.Size);
  end;
end;

function TSymmetricAlgorithmBase.DoEncrypt(const buffer: Pointer;
  count: Integer): TBuffer;
var
  p: PByte;
  plainText: TBuffer;
  cipherText: TBytes;
  paddingSize: Integer;
  startIndex: Integer;
  firstBlock: Boolean;
begin
  TArgument.CheckRange(count >= 0, 'count');
  if count = 0 then
  begin
    Exit(TBuffer.Empty);
  end;
  p := buffer;
  plainText.Size := BlockSizeInBytes;
  SetLength(cipherText, BlockSizeInBytes);
  firstBlock := True;
  while count >= 0 do
  begin
    if count >= BlockSizeInBytes then
    begin
      Move(p^, plainText.Memory^, BlockSizeInBytes);
    end
    else if PaddingMode <> pmNone then
    begin
      Move(p^, plainText.Memory^, count);
      paddingSize := BlockSizeInBytes - (count mod BlockSizeInBytes);
      startIndex := BlockSizeInBytes - paddingSize;
      AddPadding(plainText, startIndex, paddingSize);
    end
    else if count > 0 then
    begin
      raise ECryptographicException.CreateRes(@SPaddingModeMissing);
    end
    else
    begin
      Exit;
    end;
    if CipherMode = cmCBC then
    begin
      if firstBlock then
        plainText := plainText xor IV
      else
        plainText := plainText xor cipherText;
      firstBlock := False;
    end;
    DoEncryptBlock(plainText, cipherText);
    Result := Result + cipherText;
    Dec(count, BlockSizeInBytes);
    Inc(p, BlockSizeInBytes);
  end;
end;

function TSymmetricAlgorithmBase.DoDecrypt(const buffer: Pointer;
  count: Integer): TBuffer;
var
  inputBuffer, plainText: TBuffer;
  outputBuffer: TBytes;
  lastCipherText: TBuffer;
  p: PByte;
  firstBlock: Boolean;
begin
  TArgument.CheckRange(count >= 0, 'count');

  firstBlock := True;
  Result := TBuffer.Empty;
  p := buffer;
  inputBuffer.Size := BlockSizeInBytes;
  plainText.Size := BlockSizeInBytes;
  SetLength(outputBuffer, BlockSizeInBytes);
  while count >= BlockSizeInBytes do
  begin
    inputBuffer := TBuffer.Create(p, BlockSizeInBytes);
    DoDecryptBlock(inputBuffer, outputBuffer);
    if CipherMode = cmCBC then
    begin
      if firstBlock then
      begin
        plainText := outputBuffer xor IV;
        firstBlock := False;
      end
      else
      begin
        plainText := outputBuffer xor lastCipherText;
      end;
      lastCipherText := inputBuffer.Clone;
    end
    else
    begin
      plainText := outputBuffer;
    end;
    if count = BlockSizeInBytes then // FinalBlock
    begin
      RemovePadding(plainText);
    end;
    Result := Result + plainText;
    Dec(count, BlockSizeInBytes);
    Inc(p, BlockSizeInBytes);
  end;
  if count > 0 then
  begin
    raise ECryptographicException.CreateRes(@SInvalidCipherText);
  end;
end;

procedure TSymmetricAlgorithmBase.AddPadding(var buffer: TBuffer; startIndex,
  count: Integer);
var
  i: Integer;
begin
  TArgument.CheckRange(buffer.Size, startIndex, count);
  case PaddingMode of
    pmNone: ;
    pmPKCS7:
    begin
      for i := 0 to count - 1 do
      begin
        buffer[startIndex + i] := Byte(count);
      end;
    end;
    pmZeros:
    begin
      for i := 0 to count - 1 do
      begin
        buffer[startIndex + i] := 0;
      end;
    end;
    pmANSIX923:
    begin
      for i := 0 to count - 2 do
      begin
        buffer[startIndex + i] := 0;
      end;
      buffer[startIndex + count - 1] := Byte(count);
    end;
    pmISO10126:
    begin
      Randomize;
      for i := 0 to count - 2 do
      begin
        buffer[startIndex + i] := Math.RandomRange(0, 256);
      end;
      buffer[startIndex + count - 1] := Byte(count);
    end;
  end;
end;

procedure TSymmetricAlgorithmBase.RemovePadding(var buffer: TBuffer);
var
  paddingSize: Integer;
  count: Integer;
  i: Integer;
begin
  Assert(buffer.Size = BlockSizeInBytes);
  case PaddingMode of
    pmNone: ;
    pmPKCS7, pmANSIX923, pmISO10126:
    begin
      paddingSize := Integer(buffer.Last);
      if paddingSize = BlockSizeInBytes then
      begin
        // Validate
        buffer := TBuffer.Empty;
      end
      else if paddingSize < BlockSizeInBytes then
      begin
        count := BlockSizeInBytes - paddingSize;
        buffer := buffer.Left(count);
      end
      else
      begin
        raise ECryptographicException.CreateRes(@SInvalidCipherText);
      end;
    end;
    pmZeros:
    begin
      for i := buffer.Size - 1 downto 0 do
      begin
        if buffer[i] = 0 then
        begin
          buffer.Size := buffer.Size - 1;
        end;
      end;
    end;
  end;
end;

function TSymmetricAlgorithmBase.Decrypt(const buffer: Pointer;
  count: Integer): TBuffer;
begin
  Result := DoDecrypt(buffer, count);
end;

function TSymmetricAlgorithmBase.Decrypt(const buffer: TBuffer): TBuffer;
begin
  Result := Decrypt(buffer.Memory, buffer.Size);
end;

function TSymmetricAlgorithmBase.Decrypt(const buffer: array of Byte): TBuffer;
begin
  Result := Decrypt(@buffer[0], Length(buffer));
end;

function TSymmetricAlgorithmBase.Decrypt(const buffer: array of Byte;
  startIndex, count: Integer): TBuffer;
begin
  TArgument.CheckRange(buffer, startIndex, count);
  Result := Decrypt(@buffer[startIndex], count);
end;

function TSymmetricAlgorithmBase.Decrypt(const inputString: string): TBuffer;
begin
  Result := Decrypt(PByte(inputString), Length(inputString) * SizeOf(Char));
end;

function TSymmetricAlgorithmBase.Decrypt(
  const inputString: WideString): TBuffer;
begin
  Result := Decrypt(PByte(inputString), Length(inputString) * SizeOf(Char));
end;

function TSymmetricAlgorithmBase.Decrypt(
  const inputString: RawByteString): TBuffer;
begin
  Result := Decrypt(PByte(inputString), Length(inputString));
end;

procedure TSymmetricAlgorithmBase.Decrypt(inputStream, outputStream: TStream);
var
  buffer: TBytes;
  count: Integer;
  outputBuffer: TBuffer;
begin
  TArgument.CheckNotNull(inputStream, 'inputStream');
  TArgument.CheckNotNull(outputStream, 'outputStream');
  SetLength(buffer, BlockSizeInBytes);
  count := inputStream.Read(buffer[0], Length(buffer));
  while count >= BlockSizeInBytes do
  begin
    outputBuffer := Decrypt(buffer);
    outputBuffer.SaveToStream(outputStream);
    count := inputStream.Read(buffer[0], Length(buffer));
  end;
  if count > 0 then
  begin
    raise ECryptographicException.CreateRes(@SInvalidCipherText);
  end;
end;

function TSymmetricAlgorithmBase.GetCipherMode: TCipherMode;
begin
  Result := fCipherMode;
end;

function TSymmetricAlgorithmBase.GetPaddingMode: TPaddingMode;
begin
  Result := fPaddingMode;
end;

function TSymmetricAlgorithmBase.GetIV: TBuffer;
begin
  if fIV.IsEmpty then
  begin
    fIV := GenerateIV;
  end;
  Result := fIV;
end;

function TSymmetricAlgorithmBase.GetKey: TBuffer;
begin
  if fKey.IsEmpty then
  begin
    fKey := GenerateKey;
  end;
  Result := fKey;
end;

function TSymmetricAlgorithmBase.GenerateIV: TBuffer;
var
  generator: IRandomNumberGenerator;
  buffer: TBytes;
begin
  generator := TRandomNumberGenerator.Create;
  SetLength(buffer, BlockSizeInBytes);
  generator.GetBytes(buffer);
  Result := buffer;
end;

function TSymmetricAlgorithmBase.GenerateKey: TBuffer;
var
  generator: IRandomNumberGenerator;
  buffer: TBytes;
begin
  generator := TRandomNumberGenerator.Create;
  SetLength(buffer, KeySizeInBytes);
  generator.GetBytes(buffer);
  Result := buffer;
end;

function TSymmetricAlgorithmBase.GetBlockSize: Integer;
begin
  Result := fBlockSize;
end;

function TSymmetricAlgorithmBase.GetBlockSizeInBytes: Integer;
begin
  Result := BlockSize div 8;
end;

function TSymmetricAlgorithmBase.GetKeySize: Integer;
begin
  Result := fKeySize;
end;

function TSymmetricAlgorithmBase.GetKeySizeInBytes: Integer;
begin
  Result := fKeySize div 8;
end;

function TSymmetricAlgorithmBase.GetLegalBlockSizes: TSizes;
begin
  Result := fLegalBlockSizes;
end;

function TSymmetricAlgorithmBase.GetLegalKeySizes: TSizes;
begin
  Result := fLegalKeySizes;
end;

procedure TSymmetricAlgorithmBase.SetBlockSize(const value: Integer);
begin
  if not fLegalBlockSizes.Contains(value) then
  begin
    raise ECryptographicException.CreateResFmt(@SIllegalBlockSize, [value]);
  end;
  fBlockSize := value;
end;

procedure TSymmetricAlgorithmBase.SetKeySize(const value: Integer);
begin
  if not fLegalKeySizes.Contains(value) then
  begin
    raise ECryptographicException.CreateResFmt(@SIllegalKeySize, [value]);
  end;
  fKeySize := value;
end;

procedure TSymmetricAlgorithmBase.SetCipherMode(const value: TCipherMode);
begin
  if not (value in [cmCBC, cmECB]) then
  begin
    raise ENotSupportedException.CreateResFmt(@SNotSupportedCipherMode, [TEnum.GetName<TCipherMode>(value)]);
  end;
  fCipherMode := value;
end;

procedure TSymmetricAlgorithmBase.SetPaddingMode(const value: TPaddingMode);
begin
  fPaddingMode := value;
end;

procedure TSymmetricAlgorithmBase.SetIV(const value: TBuffer);
begin
  if value.Size <> BlockSizeInBytes then
  begin
    raise ECryptographicException.CreateResFmt(@SIllegalIVSize, [value.Size]);
  end;
  fIV := value;
end;

procedure TSymmetricAlgorithmBase.SetKey(const value: TBuffer);
begin
  ValidateKey(value);
  fKey := TBuffer.Create(value.Memory, value.Size);
end;

{$ENDREGION}


{$REGION 'TRandomNumberGenerator'}

procedure TRandomNumberGenerator.GetBytes(var data: TBytes);
var
  i: Integer;
begin
  Randomize;
  for i := 0 to High(data) do
  begin
    data[i] := RandomRange(0, $FF + 1);
  end;
end;

procedure TRandomNumberGenerator.GetNonZeroBytes(var data: TBytes);
var
  i: Integer;
begin
  Randomize;
  for i := 0 to High(data) do
  begin
    data[i] := RandomRange(1, $FF + 1);
  end;
end;

{$ENDREGION}

end.
