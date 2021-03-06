package org.opendaylight.yangtools.orm.generators;

import org.opendaylight.mdsal.binding.model.api.CodeGenerator;
import org.opendaylight.mdsal.binding.model.api.GeneratedTransferObject;
import org.opendaylight.mdsal.binding.model.api.GeneratedType;
import org.opendaylight.mdsal.binding.model.api.Type;
import org.opendaylight.yangtools.yang.binding.Augmentable;
import org.opendaylight.yangtools.yang.binding.Augmentation;

import org.opendaylight.yangtools.orm.templates.PojoTemplate;

public class PojoGenerator implements CodeGenerator {

	/**
	 * Passes via list of implemented types in <code>type</code>.
	 *
	 * @param type
	 *            JAVA <code>Type</code>
	 * @return boolean value which is true if any of implemented types is of the
	 *         type <code>Augmentable</code>.
	 */
	@Override
	public boolean isAcceptable(Type type) {
		if (type instanceof GeneratedType && !(type instanceof GeneratedTransferObject)) {
			for (Type t : ((GeneratedType) type).getImplements()) {
				// "rpc" and "grouping" elements do not implement Augmentable
				if (t.getFullyQualifiedName().equals(Augmentable.class.getName())) {
					return true;
				} else if (t.getFullyQualifiedName().equals(Augmentation.class.getName())) {
					return true;
				}

			}
		}
		return false;
	}

	/**
	 * Generates JAVA source code for generated type <code>Type</code>. The code is
	 * generated according to the template source code template which is written in
	 * XTEND language.
	 */
	@Override
	public String generate(Type type) {
		if (type instanceof GeneratedType && !(type instanceof GeneratedTransferObject)) {
			final GeneratedType genType = (GeneratedType) type;
			final PojoTemplate template = new PojoTemplate(genType);
			return template.generate();
		}
		return "";
	}

	@Override
	public String getUnitName(Type type) {
		return type.getName()+"Entity";
	}

}
