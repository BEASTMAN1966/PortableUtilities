${SegmentFile}

;=== START INTEGRITY CHECK 1.1 Var
	Var bolCustomIntegrityCheckStartUnsupported
	Var strCustomIntegrityCheckVersion
;=== END INTEGRITY CHECK

Var CUSTOM_Exists_IobitUninstaller_Scheduled_Task
Var CUSTOM_Exists_IobitUninstaller_Scheduled_Task_User
Var CUSTOM_LoggedInUser

${Segment.OnInit}
	;=== START INTEGRITY CHECK 1.1 OnInit
	;Check for improper install/upgrade without running the PA.c Installer which can cause issues
	;Designed to not require ReadINIStrWithDefault which is not included in the PA.c Launcher code
	
	${If} ${FileExists} "$EXEDIR\App\AppInfo\appinfo.ini"
		${If} ${FileExists} "$EXEDIR\App\AppInfo\pac_installer_log.ini"
			ReadINIStr $R0 "$EXEDIR\App\AppInfo\pac_installer_log.ini" "PortableApps.comInstaller" "Info2"
			${If} $R0 == "This file was generated by the PortableApps.com Installer wizard and modified by the official PortableApps.com Installer TM Rare Ideas, LLC as the app was installed."
				StrCpy $R1 "true"
			${Else}
				StrCpy $R1 "false"
			${EndIf}
		${Else}
			StrCpy $R1 "false"
		${EndIf}
	${Else}
		StrCpy $R1 "true"
	${EndIf}
	
	${If} $R1 == "false"
		;Upgrade or install sans the PortableApps.com Installer which can cause compatibility issues
		ClearErrors
		ReadINIStr $0 "$EXEDIR\App\AppInfo\appinfo.ini" "Version" "PackageVersion"
		${If} ${Errors}
		${OrIf} $0 == ""
			StrCpy $0 "0.0.0.1"
			ClearErrors
		${EndIf}

		ClearErrors
		ReadINIStr $1 "$EXEDIR\Data\settings\${AppID}Settings.ini" "${AppID}Settings" "InvalidPackageWarningShown"
		${If} ${Errors}
		${OrIf} $1 == ""
			StrCpy $1 "0.0.0.0"
			ClearErrors
		${EndIf}

		${VersionCompare} $0 $1 $2
		${If} $2 == 1		
			MessageBox MB_YESNO|MB_ICONQUESTION|MB_DEFBUTTON2 `Integrity Failure Warning: ${NamePortable} was installed or upgraded without using its installer and some critical files may have been modified.  This could cause data loss, personal data left behind on a shared PC, functionality issues, and/or may be a violation of the application's license. Neither the application publisher nor PortableApps.com will be responsible for any issues you encounter.$\r$\n$\r$\nWould you like to start ${NamePortable} in its current unsupported state?` IDYES CustomIntegrityCheckGotoStartAnyway IDNO CustomIntegrityCheckGotoDownloadQuestion
		
			CustomIntegrityCheckGotoDownloadQuestion:
			;Check to ensure we have a valid homepage before asking the user
			StrCpy $R0 ""
			${If} ${FileExists} "$EXEDIR\App\AppInfo\appinfo.ini"
				ReadINIStr $R0 "$EXEDIR\App\AppInfo\appinfo.ini" "Details" "Homepage"
			${EndIf}
			
			${If} $R0 == ""
				Abort
			${Else}
				StrCpy $R1 $R0 4
				${If} $R1 != "http"
				${AndIf} $R1 != "HTTP"
					StrCpy $R0 "http://$R0"
				${EndIf}
			${EndIf}
			
			MessageBox MB_YESNO|MB_ICONQUESTION|MB_DEFBUTTON1 `Would you like to visit the ${NamePortable} homepage to download the app and upgrade your current install?` IDYES CustomIntegrityCheckGotoURL IDNO CustomIntegrityCheckGotoAbort

			CustomIntegrityCheckGotoURL:		
			ExecShell "open" $R0
			Abort
						
			CustomIntegrityCheckGotoAbort:
			Abort
	
			CustomIntegrityCheckGotoStartAnyway:
			StrCpy $bolCustomIntegrityCheckStartUnsupported true
			StrCpy $strCustomIntegrityCheckVersion $0
		${EndIf}
	${EndIf}
	;=== END INTEGRITY CHECK
!macroend

${SegmentPrePrimary}
	;=== START INTEGRITY CHECK 1.1 PrePrimary
	${If} $bolCustomIntegrityCheckStartUnsupported == true
		WriteINIStr "$EXEDIR\Data\settings\${AppID}Settings.ini" "${AppID}Settings" "InvalidPackageWarningShown" $strCustomIntegrityCheckVersion
	${EndIf}	
	;=== END INTEGRITY CHECK

	System::Call "advapi32::GetUserName(t .r0, *i ${NSIS_MAX_STRLEN} r1) i.r2"
	StrCpy $CUSTOM_LoggedInUser $0

	${If} ${FileExists} "$SYSDIR\Tasks\Uninstaller_SkipUac_$CUSTOM_LoggedInUser"
		StrCpy $CUSTOM_Exists_IobitUninstaller_Scheduled_Task_User true
	${EndIf}
	
	${If} ${FileExists} "$SYSDIR\Tasks\Uninstaller_SkipUac_Administrator"
		StrCpy $CUSTOM_Exists_IobitUninstaller_Scheduled_Task true
	${EndIf}
!macroend


${SegmentPostPrimary}
	Delete $DataDirectory\uninstaller\SoftwareCache.ini
	
	System::Call "advapi32::GetUserName(t .r0, *i ${NSIS_MAX_STRLEN} r1) i.r2"
	
	${If} $CUSTOM_Exists_SmartDefrag_Scheduled_Task_User != true
		nsExec::Exec /TIMEOUT=10000 `"schtasks.exe" /delete /tn Uninstaller_SkipUac_$CUSTOM_LoggedInUser /f`
		Pop $0
	${EndIf}
	
	${If} $CUSTOM_Exists_SmartDefrag_Scheduled_Task != true
		nsExec::Exec /TIMEOUT=10000 `"schtasks.exe" /delete /tn Uninstaller_SkipUac_Administrator /f`
		Pop $0
	${EndIf}
	
	System::Call "wininet::DeleteUrlCacheEntryW(t'http://download.iobit.com/uninstaller3/UninstallRote.dbd')i .r2"
	System::Call "wininet::DeleteUrlCacheEntryW(t'http://download.iobit.com/uninstaller4/UninstallRote.dbd')i .r2"
	System::Call "wininet::DeleteUrlCacheEntryW(t'http://download.iobit.com/uninstaller5/UninstallRote.dbd')i .r2"
	System::Call "wininet::DeleteUrlCacheEntryW(t'http://download.iobit.com/uninstaller6/UninstallRote.dbd')i .r2"
	System::Call "wininet::DeleteUrlCacheEntryW(t'http://download.iobit.com/uninstaller7/UninstallRote.dbd')i .r2"
	System::Call "wininet::DeleteUrlCacheEntryW(t'http://update.iobit.com/dl/uninstaller/UninstallRote.dbd')i .r2"
	System::Call "wininet::DeleteUrlCacheEntryW(t'http://update.iobit.com/dl/uninstaller/uninstall_qdb.dbd')i .r2"
!macroend