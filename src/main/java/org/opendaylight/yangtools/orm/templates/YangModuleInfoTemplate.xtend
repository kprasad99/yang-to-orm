/*
 * Copyright (c) 2013 Cisco Systems, Inc. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.yangtools.orm.templates

import static org.opendaylight.yangtools.orm.mapping.BindingMapping.MODULE_INFO_CLASS_NAME
import static org.opendaylight.yangtools.orm.mapping.BindingMapping.getClassName
import static org.opendaylight.yangtools.orm.mapping.BindingMapping.getRootPackageName

import com.google.common.base.Preconditions
import java.text.DateFormat
import java.text.SimpleDateFormat
import java.util.Collections
import java.util.HashSet
import java.util.LinkedHashMap
import java.util.Map
import java.util.Optional
import java.util.Set
import java.util.function.Function
import org.opendaylight.mdsal.binding.model.api.ParameterizedType
import org.opendaylight.mdsal.binding.model.api.Type
import org.opendaylight.mdsal.binding.model.api.WildcardType
import org.opendaylight.mdsal.binding.model.util.Types
import org.opendaylight.yangtools.yang.model.api.Module
import org.opendaylight.yangtools.yang.model.api.SchemaContext
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import org.opendaylight.yang.orm.model.YangModuleInfoMarker
import org.opendaylight.yang.orm.model.YangModuleInfo
import org.opendaylight.yang.orm.model.ModuleInfo

class YangModuleInfoTemplate {

    val Module module
    val SchemaContext ctx
    val Map<String, String> importMap = new LinkedHashMap()
    val Function<Module, Optional<String>> moduleFilePathResolver

    val String packageName;

    
    new(Module module, SchemaContext ctx, Function<Module, Optional<String>> moduleFilePathResolver) {
        Preconditions.checkArgument(module !== null, "Module must not be null.");
        this.module = module
        this.ctx = ctx
        this.moduleFilePathResolver = moduleFilePathResolver
        packageName = getRootPackageName(module.getQNameModule());
    }

    def String generate() {
        val body = '''
            
            @«YangModuleInfoMarker.importedName»
            public final class «MODULE_INFO_CLASS_NAME» implements «YangModuleInfo.importedName» {


                private final «String.importedName» name = "«module.name»";
                private final String namespace = "«module.namespace.toString»";
                «val DateFormat df = new SimpleDateFormat("yyyy-MM-dd")»
                private final «LocalDate.importedName» revision = LocalDate.parse("«df.format(module.revision)»", «DateTimeFormatter.importedName».ISO_DATE);
                private final String resourcePath = "«sourcePath(module)»";

                «classBody(module, MODULE_INFO_CLASS_NAME)»
            }
        '''
        return '''
            package «packageName» ;
            «imports»
            «body»
        '''.toString
    }

    private def CharSequence classBody(Module m, String className) '''
        @Override
        public «ModuleInfo.importedName» getModuleInfo() { 	
            «Set.importedName»<ModuleInfo> importedModules = «IF m.imports.empty»«Collections.importedName».emptySet();«ELSE»new «HashSet.importedName»<>();
            «FOR imp : m.imports SEPARATOR '\n' »
                «val name = imp.moduleName»
                «val rev = imp.revision»
                «val DateFormat df = new SimpleDateFormat("yyyy-MM-dd")»
                 importedModules.add(new ModuleInfo("«name»", LocalDate.parse("«df.format(rev)»", «DateTimeFormatter.importedName».ISO_DATE)));
            «ENDFOR»
            «ENDIF»
            «'\n'»
            return new ModuleInfo(name, revision, namespace, importedModules);
        }


        @Override
        public String toString() {
            «StringBuilder.importedName» sb = new StringBuilder(this.getClass().getCanonicalName());
            sb.append("[");
            sb.append("name = " + name);
            sb.append(", namespace = " + namespace);
            sb.append(", revision = " + revision);
            sb.append(", resourcePath = " + resourcePath);
            sb.append("]");
            return sb.toString();
        }

        «generateSubInfo(m)»

    '''

    private def sourcePath(Module module) {
        val opt = moduleFilePathResolver.apply(module)
        Preconditions.checkState(opt.isPresent, "Module %s does not have a file path", module)
        return opt.get
    }

    private def imports() '''
        «IF !importMap.empty»
            «FOR entry : importMap.entrySet»
                «IF entry.value != getRootPackageName(module.QNameModule)»
                    import «entry.value».«entry.key»;
                «ENDIF»
            «ENDFOR»
        «ENDIF»
    '''

    final protected def importedName(Class<?> cls) {
        val Type intype = Types.typeForClass(cls)
        putTypeIntoImports(intype);
        getExplicitType(intype)
    }

    final def void putTypeIntoImports(Type type) {
        val String typeName = type.getName();
        val String typePackageName = type.getPackageName();
        if (typePackageName.startsWith("java.lang") || typePackageName.isEmpty()) {
            return;
        }
        if (!importMap.containsKey(typeName)) {
            importMap.put(typeName, typePackageName);
        }
        if (type instanceof ParameterizedType) {
            val Type[] params = type.getActualTypeArguments()
            if (params !== null) {
                for (Type param : params) {
                    putTypeIntoImports(param);
                }
            }
        }
    }

    final def String getExplicitType(Type type) {
        val String typePackageName = type.getPackageName();
        val String typeName = type.getName();
        val String importedPackageName = importMap.get(typeName);
        var StringBuilder builder;
        if (typePackageName.equals(importedPackageName)) {
            builder = new StringBuilder(type.getName());
            if (builder.toString().equals("Void")) {
                return "void";
            }
            addActualTypeParameters(builder, type);
        } else {
            if (type.equals(Types.voidType())) {
                return "void";
            }
            builder = new StringBuilder();
            if (!typePackageName.isEmpty()) {
                builder.append(typePackageName + Constants.DOT + type.getName());
            } else {
                builder.append(type.getName());
            }
            addActualTypeParameters(builder, type);
        }
        return builder.toString();
    }

    final def StringBuilder addActualTypeParameters(StringBuilder builder, Type type) {
        if (type instanceof ParameterizedType) {
            val Type[] pTypes = type.getActualTypeArguments();
            builder.append('<');
            builder.append(getParameters(pTypes));
            builder.append('>');
        }
        return builder;
    }

    final def String getParameters(Type[] pTypes) {
        if (pTypes === null || pTypes.length == 0) {
            return "?";
        }
        val StringBuilder builder = new StringBuilder();

        var int i = 0;
        for (pType : pTypes) {
            val Type t = pTypes.get(i)

            var String separator = ",";
            if (i == (pTypes.length - 1)) {
                separator = "";
            }

            var String wildcardParam = "";
            if (t.equals(Types.voidType())) {
                builder.append("java.lang.Void" + separator);
            } else {

                if (t instanceof WildcardType) {
                    wildcardParam = "? extends ";
                }

                builder.append(wildcardParam + getExplicitType(t) + separator);
                i = i + 1
            }
        }
        return builder.toString();
    }

    private def generateSubInfo(Module module) '''
        «FOR submodule : module.submodules»
            private static final class «getClassName(submodule.name)»Info implements «YangModuleInfo.importedName» {

                private static final «YangModuleInfo.importedName» INSTANCE = new «getClassName(submodule.name)»Info();

                private final «String.importedName» name = "«submodule.name»";
                private final «String.importedName» namespace = "«submodule.namespace.toString»";
                «val DateFormat df = new SimpleDateFormat("yyyy-MM-dd")»
                private final «String.importedName» revision = "«df.format(submodule.revision)»";
                private final «String.importedName» resourcePath = "«sourcePath(submodule)»";

                private final «Set.importedName»<YangModuleInfo> importedModules;

                public static «YangModuleInfo.importedName» getInstance() {
                    return INSTANCE;
                }

                «classBody(submodule, getClassName(submodule.name + "Info"))»
            }
        «ENDFOR»
    '''

}
