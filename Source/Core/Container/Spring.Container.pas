{***************************************************************************}
{                                                                           }
{           Spring Framework for Delphi                                     }
{                                                                           }
{           Copyright (c) 2009-2014 Spring4D Team                           }
{                                                                           }
{           http://www.spring4d.org                                         }
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

{TODO -oOwner -cGeneral : Thread Safety}
unit Spring.Container;

{$I Spring.inc}

interface

uses
  Rtti,
  Spring,
  Spring.Collections,
  Spring.Container.Common,
  Spring.Container.Core,
  Spring.Container.Registration,
  Spring.Services;

type
  ///	<summary>
  ///	  Represents a Dependency Injection Container.
  ///	</summary>
  TContainer = class(TInterfaceBase, IKernel, IKernelInternal, IContainer)
  private
    fRegistry: IComponentRegistry;
    fBuilder: IComponentBuilder;
    fInjector: IDependencyInjector;
    fRegistrationManager: TRegistrationManager;
    fResolver: IDependencyResolver;
    fExtensions: IList<IContainerExtension>;
    class var GlobalInstance: TContainer;
    function GetKernel: IKernel;
    type
      TValueArray = array of TValue;
  protected
    class constructor Create;
    class destructor Destroy;
  {$REGION 'Implements IKernel'}
    function GetBuilder: IComponentBuilder;
    function GetInjector: IDependencyInjector;
    function GetRegistry: IComponentRegistry;
    function GetResolver: IDependencyResolver;
  {$ENDREGION}
    procedure InitializeInspectors; virtual;
    property Builder: IComponentBuilder read GetBuilder;
    property Injector: IDependencyInjector read GetInjector;
    property Registry: IComponentRegistry read GetRegistry;
    property Resolver: IDependencyResolver read GetResolver;
  public
    constructor Create;
    destructor Destroy; override;

    procedure AddExtension(const extension: IContainerExtension); overload;
    procedure AddExtension<T: IContainerExtension, constructor>; overload;

    function RegisterInstance<TServiceType>(const instance: TServiceType;
      const name: string = ''): TRegistration<TServiceType>; overload;

    function RegisterType<TComponentType>: TRegistration<TComponentType>; overload;
    function RegisterType(componentType: PTypeInfo): IRegistration; overload;
    function RegisterType<TServiceType, TComponentType>(
      const name: string = ''): TRegistration<TComponentType>; overload;
    function RegisterType(serviceType, componentType: PTypeInfo;
      const name: string = ''): IRegistration; overload;

    procedure Build;

    function Resolve<T>: T; overload;
    function Resolve<T>(const arguments: array of TValue): T; overload;
    function Resolve<T>(const name: string): T; overload;
    function Resolve<T>(const name: string;
      const arguments: array of TValue): T; overload;
    function Resolve(serviceType: PTypeInfo): TValue; overload;
    function Resolve(serviceType: PTypeInfo;
      const arguments: array of TValue): TValue; overload;
    function Resolve(const name: string): TValue; overload;
    function Resolve(const name: string;
      const arguments: array of TValue): TValue; overload;

    function ResolveAll<TServiceType>: TArray<TServiceType>; overload;
    function ResolveAll(serviceType: PTypeInfo): TArray<TValue>; overload;

{$IFNDEF AUTOREFCOUNT}
    { Experimental Release Methods }
    procedure Release(instance: TObject); overload;
    procedure Release(instance: IInterface); overload;
{$ELSE}
    // Dangerous since the instance should be cleared by this function but
    // passing as var is not possible here
{$ENDIF}

    property Kernel: IKernel read GetKernel;
  end;

  ///	<summary>
  ///	  Adapter to get access to a <see cref="TContainer" /> instance over the
  ///	  <see cref="Spring.Services|IServiceLocator" /> interface.
  ///	</summary>
  TServiceLocatorAdapter = class(TInterfacedObject, IServiceLocator)
  private
    {$IFDEF WEAKREF}[Weak]{$ENDIF}
    fContainer: TContainer;
    class var GlobalInstance: IServiceLocator;
    class constructor Create;
  public
    constructor Create(const container: TContainer);

    function GetService(serviceType: PTypeInfo): TValue; overload;
    function GetService(serviceType: PTypeInfo; const name: string): TValue; overload;
    function GetService(serviceType: PTypeInfo; const args: array of TValue): TValue; overload;
    function GetService(serviceType: PTypeInfo; const name: string; const args: array of TValue): TValue; overload;

    function GetAllServices(serviceType: PTypeInfo): TArray<TValue>; overload;

    function HasService(serviceType: PTypeInfo): Boolean; overload;
    function HasService(serviceType: PTypeInfo; const name: string): Boolean; overload;
  end;


{$REGION 'Exceptions'}

  EContainerException = Spring.Container.Core.EContainerException;
  ERegistrationException = Spring.Container.Core.ERegistrationException;
  EResolveException = Spring.Container.Core.EResolveException;
  ECircularDependencyException = Spring.Container.Core.ECircularDependencyException;
  EActivatorException = Spring.Container.Core.EActivatorException;

{$ENDREGION}

procedure CleanupGlobalContainer;

/// <summary>
///   Returns global instance of the container.
/// </summary>
{$IFDEF AUTOREFCOUNT}[Result: Unsafe]{$ENDIF}
function GlobalContainer: TContainer; {$IFNDEF AUTOREFCOUNT}inline;{$ENDIF}

implementation

uses
  SysUtils,
  TypInfo,
  Spring.Container.Builder,
  Spring.Container.CreationContext,
  Spring.Container.Injection,
  Spring.Container.LifetimeManager,
  Spring.Container.Resolvers,
  Spring.Container.ResourceStrings,
  Spring.Helpers,
  Spring.Reflection;


function GlobalContainer: TContainer;
begin
  Result := TContainer.GlobalInstance;
end;


{$REGION 'TContainer'}

class constructor TContainer.Create;
begin
  GlobalInstance := TContainer.Create;
end;

class destructor TContainer.Destroy;
begin
  GlobalInstance.Free;
end;

constructor TContainer.Create;
begin
  inherited Create;
  fRegistry := TComponentRegistry.Create(Self);
  fBuilder := TComponentBuilder.Create(Self);
  fInjector := TDependencyInjector.Create;
  fRegistrationManager := TRegistrationManager.Create(Self);
  fResolver := TDependencyResolver.Create(Self);
  fExtensions := TCollections.CreateInterfaceList<IContainerExtension>;
  InitializeInspectors;

  fResolver.AddSubResolver(TLazyResolver.Create(Self));
  fResolver.AddSubResolver(TDynamicArrayResolver.Create(Self));
  fResolver.AddSubResolver(TListResolver.Create(Self));
end;

destructor TContainer.Destroy;
begin
  fRegistrationManager.Free;
  fBuilder.ClearInspectors;
  fRegistry.UnregisterAll;

  // Since many of these object hold Self as a field, it is better (and on
  // Android required) to release these interfaces here rather than in
  // CleanupInstance (which on android produces a lots of AVs probably due
  // to calling virtual __ObjRelease on almost destroyed object)
  fExtensions := nil;
  fResolver := nil;
  fInjector := nil;
  fBuilder := nil;
  fRegistry := nil;

  inherited Destroy;
end;

procedure TContainer.AddExtension(const extension: IContainerExtension);
begin
  fExtensions.Add(extension);
  extension.InitializeExtension(Self);
  extension.Initialize;
end;

procedure TContainer.AddExtension<T>;
var
  extension: IContainerExtension;
begin
  extension := T.Create;
  AddExtension(extension);
end;

procedure TContainer.Build;
begin
  fBuilder.BuildAll;
end;

procedure TContainer.InitializeInspectors;
var
  inspectors: TArray<IBuilderInspector>;
  inspector: IBuilderInspector;
begin
  inspectors := TArray<IBuilderInspector>.Create(
    TInterfaceInspector.Create,
    TComponentActivatorInspector.Create,
    TLifetimeInspector.Create,
    TInjectionTargetInspector.Create,
    TConstructorInspector.Create,
    TPropertyInspector.Create,
    TMethodInspector.Create,
    TFieldInspector.Create
  );
  for inspector in inspectors do
    fBuilder.AddInspector(inspector);
end;

function TContainer.GetBuilder: IComponentBuilder;
begin
  Result := fBuilder;
end;

function TContainer.GetRegistry: IComponentRegistry;
begin
  Result := fRegistry;
end;

function TContainer.GetInjector: IDependencyInjector;
begin
  Result := fInjector;
end;

function TContainer.GetKernel: IKernel;
begin
  Result := Self;
end;

function TContainer.GetResolver: IDependencyResolver;
begin
  Result := fResolver;
end;

function TContainer.RegisterInstance<TServiceType>(const instance: TServiceType;
  const name: string): TRegistration<TServiceType>;
begin
  Result := fRegistrationManager.RegisterType<TServiceType>;
  Result := Result.DelegateTo(
    function: TServiceType
    begin
      Result := instance;
    end);
  Result := Result.Implements<TServiceType>(name);
end;

function TContainer.RegisterType<TComponentType>: TRegistration<TComponentType>;
begin
  Result := fRegistrationManager.RegisterType<TComponentType>;
end;

function TContainer.RegisterType<TServiceType, TComponentType>(
  const name: string): TRegistration<TComponentType>;
begin
  Result := fRegistrationManager.RegisterType<TComponentType>;
  Result := Result.Implements<TServiceType>(name);
end;

function TContainer.RegisterType(componentType: PTypeInfo): IRegistration;
begin
  Result := fRegistrationManager.RegisterType(componentType);
end;

function TContainer.RegisterType(serviceType, componentType: PTypeInfo;
  const name: string): IRegistration;
begin
  Result := fRegistrationManager.RegisterType(componentType);
  Result := Result.Implements(serviceType, name);
end;

function TContainer.Resolve<T>: T;
var
  value: TValue;
begin
  value := Resolve(TypeInfo(T), []);
  Result := value.AsType<T>;
end;

function TContainer.Resolve<T>(const arguments: array of TValue): T;
var
  value: TValue;
begin
  value := Resolve(TypeInfo(T), arguments);
  Result := value.AsType<T>;
end;

function TContainer.Resolve<T>(const name: string): T;
var
  value: TValue;
begin
  value := Resolve(name, []);
  Result := value.AsType<T>;
end;

function TContainer.Resolve<T>(const name: string;
  const arguments: array of TValue): T;
var
  value: TValue;
begin
  value := Resolve(name, arguments);
  Result := value.AsType<T>;
end;

function TContainer.Resolve(serviceType: PTypeInfo): TValue;
begin
  Result := Resolve(serviceType, []);
end;

function TContainer.Resolve(serviceType: PTypeInfo;
  const arguments: array of TValue): TValue;
var
  componentModel: TComponentModel;
  context: ICreationContext;
  targetType: TRttiType;
begin
  componentModel := fRegistry.FindDefault(serviceType);
  context := TCreationContext.Create(componentModel, arguments);
  targetType := TType.GetType(serviceType);
  Result := fResolver.Resolve(
    context, componentModel, TDependencyModel.Create(targetType, nil), nil);
end;

function TContainer.Resolve(const name: string): TValue;
begin
  Result := Resolve(name, []);
end;

function TContainer.Resolve(const name: string;
  const arguments: array of TValue): TValue;
var
  componentModel: TComponentModel;
  context: ICreationContext;
  serviceType: PTypeInfo;
  targetType: TRttiType;
begin
  componentModel := fRegistry.FindOne(name);
  if not Assigned(componentModel) then
    raise EResolveException.CreateResFmt(@SServiceNotFound, [name]);
  context := TCreationContext.Create(componentModel, arguments);
  serviceType := componentModel.GetServiceType(name);
  targetType := TType.GetType(serviceType);
  Result := fResolver.Resolve(
    context, componentModel, TDependencyModel.Create(targetType, nil), name);
end;

function TContainer.ResolveAll<TServiceType>: TArray<TServiceType>;
var
  values: TArray<TValue>;
  i: Integer;
begin
  values := ResolveAll(TypeInfo(TServiceType));
  SetLength(Result, Length(values));
  for i := Low(values) to High(values) do
    Result[i] := TValueArray(values)[i].AsType<TServiceType>;
end;

function TContainer.ResolveAll(serviceType: PTypeInfo): TArray<TValue>;
var
  targetType: TRttiType;
  models: TArray<TComponentModel>;
  i: Integer;
  context: ICreationContext;
  serviceName: string;
begin
  targetType := TType.GetType(serviceType);
  // TODO: remove dependency on lazy type
  if TType.IsLazy(serviceType) then
    serviceType := targetType.GetGenericArguments[0].Handle;
  models := fRegistry.FindAll(serviceType).ToArray;
  SetLength(Result, Length(models));
  for i := Low(models) to High(models) do
  begin
    context := TCreationContext.Create(models[i], []);
    serviceName := models[i].GetServiceName(serviceType);
    Result[i] := fResolver.Resolve(
      context, models[i], TDependencyModel.Create(targetType, nil), serviceName);
  end;
end;

{$IFNDEF AUTOREFCOUNT}
procedure TContainer.Release(instance: TObject);
var
  model: TComponentModel;
begin
  Guard.CheckNotNull(instance, 'instance');

  model := fRegistry.FindOne(instance.ClassInfo);
  if model = nil then
    raise EContainerException.CreateResFmt(@STypeNotFound, [instance.ClassName]);
  model.LifetimeManager.Release(instance);
end;

procedure TContainer.Release(instance: IInterface);
begin
  Guard.CheckNotNull(instance, 'instance');
  {TODO -oOwner -cGeneral : Release instance of IInterface }
end;
{$ENDIF}

{$ENDREGION}


{$REGION 'TServiceLocatorAdapter'}

class constructor TServiceLocatorAdapter.Create;
begin
  GlobalInstance := TServiceLocatorAdapter.Create(GlobalContainer);
  ServiceLocator.Initialize(
    function: IServiceLocator
    begin
      Result := GlobalInstance;
    end);
end;

constructor TServiceLocatorAdapter.Create(const container: TContainer);
begin
  inherited Create;
  fContainer := container;
end;

function TServiceLocatorAdapter.GetService(serviceType: PTypeInfo): TValue;
begin
  Result := fContainer.Resolve(serviceType);
end;

function TServiceLocatorAdapter.GetService(serviceType: PTypeInfo; const name: string): TValue;
begin
  Result := fContainer.Resolve({serviceType, }name);
end;

function TServiceLocatorAdapter.GetService(serviceType: PTypeInfo;
  const args: array of TValue): TValue;
begin
  Result := fContainer.Resolve(serviceType, args);
end;

function TServiceLocatorAdapter.GetService(serviceType: PTypeInfo;
  const name: string; const args: array of TValue): TValue;
begin
  Result := fContainer.Resolve({serviceType, }name, args);
end;

function TServiceLocatorAdapter.GetAllServices(serviceType: PTypeInfo): TArray<TValue>;
begin
  Result := fContainer.ResolveAll(serviceType);
end;

function TServiceLocatorAdapter.HasService(serviceType: PTypeInfo): Boolean;
begin
  Result := fContainer.Registry.HasService(serviceType);
end;

function TServiceLocatorAdapter.HasService(serviceType: PTypeInfo; const name: string): Boolean;
begin
  Result := fContainer.Registry.HasService(serviceType, name);
end;

{$ENDREGION}


procedure CleanupGlobalContainer;
begin
  TServiceLocatorAdapter.GlobalInstance := nil;
  FreeAndNil(TContainer.GlobalInstance);
end;

end.
