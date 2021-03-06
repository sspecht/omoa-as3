﻿/*
This file is part of OMOA.

(C) Leibniz Institute for Regional Geography,
    Leipzig, Germany

OMOA is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

OMOA is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License
along with OMOA.  If not, see <http://www.gnu.org/licenses/>.
*/

package org.omoa.datamodel {
	
	import flash.events.EventDispatcher;
	import org.omoa.framework.Datum;
	import org.omoa.framework.Description;
	import org.omoa.framework.ModelDimension;
	
	/**
	*
	* @author Sebastian Specht
	*/

	public class GenericDataModel extends AbstractDataModel {

		protected var data:Object = new Object();
		
		private var inInitialization:Boolean = true;
		private var dimensionIndexOffset:Vector.<int>;
		private var countPDimensions:Number = 0;

		public function GenericDataModel(id:String) {
			super(id);
		}

		override public function addDatum(datum:Datum):void {
			var i:int;
			var index:int;
			var valueIndex:int;
			var storageObject:Object;
			if (inInitialization) {
				throw new Error( "No valueDimension given in the DataModel. You can't add a datum." );
			}
			if (datum.description.representsScalar) {
				storageObject = data;
				for (i = 1; i < datum.description.selectedDimensionCount(); i++) {
					if (!storageObject[datum.description.selectedCode(i)]) {
						storageObject[datum.description.selectedCode(i)] = new Object();
					}
					storageObject = storageObject[datum.description.selectedCode(i)];
				}
				storageObject[datum.description.selectedCode(datum.description.valueDimensionOrder())] = datum.value;
			} else {
				throw new Error( "Description does not represent a scalar value." );
			}
		}
		
		override public function getDatum(description:Description):Datum {
			var datum:Datum = new Datum();
			datum.description = description;
			
			updateDatum( datum );
			return datum;
		}
		
		/**
		 * Updates a <code>Datum</code> with the data value according to the <code>Description</code>.
		 * This is the fastest way to request a data value, since it does not create any object.
		 * The description of the datum needs to point to a scalar value, otherwise the value property of
		 * the datum will be <code>NaN</code>.
		 * @param	datum	The Datum you want to be updated according to the description 
		 * 					property (Description).
		 */
		override public function updateDatum(datum:Datum):void {
			var result:Object = data;
			var i:int;
			
			for (i = 1; i < datum.description.valueDimensionOrder(); i++) {
				if (result) {
					result = result[ datum.description.selectedCode(i)];
				} else {
					break;
				}
			}
			if (result) {
				if (datum.description.representsScalar) {
					datum.value = result[datum.description.selectedCode(datum.description.valueDimensionOrder())];
				} else {
					datum.value = result;
				}
			}
		}

		override public function addPropertyDimension(propertyDimension:ModelDimension):void {
			if (inInitialization) {
				super.addPropertyDimension( propertyDimension );
			} else {
				throw new Error( "Model initialization finished. You can't add a PropertyDimensions after a ValueDimension." );
			}
		}

		override public function addValueDimension(valueDimension:ModelDimension):void {
			super.addValueDimension( valueDimension );
			
			var i:int;
			var index:int;
			if (inInitialization) {
				inInitialization = false;
				countPDimensions = propertyDimensions.length;
			}
		}
		
		override public function toString():String {
			var p:ModelDimension;
			var s:String = "|DataModel: " + propertyDimensions.length + " PropertyDimensions and " + valueDimensions.length + " ValueDimensions";
			s += "\n|---PropertyDimensions:";
			for each (p in propertyDimensions) {
				s += "\n|   " + p.classificationID + " " + p.title + " " + p.codeCount + " Ausprägungen: " + p.codes;
			}
			s += "\n|---ValueDimensions:";
			for each (p in valueDimensions) {
				s += "\n|   " + p.classificationID + " " + p.title + " " + p.codeCount + " Ausprägungen";
			}
			
			return s;
		}


	}
}