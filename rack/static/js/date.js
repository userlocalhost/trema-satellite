	/**************************************************
	 * [�@�\]	���t�I�u�W�F�N�g���當����ɕϊ����܂�	 * [����]	date	�Ώۂ̓��t�I�u�W�F�N�g
	 * 			format	�t�H�[�}�b�g
	 * [�ߒl]	�t�H�[�}�b�g��̕�����
	 **************************************************/
	function comDateFormat(date, format){

		var result = format;

		var f;
		var rep;

		var yobi = new Array('��', '��', '��', '��', '��', '��', '�y');

		f = 'yyyy';
		if ( result.indexOf(f) > -1 ) {
			rep = date.getFullYear();
			result = result.replace(/yyyy/, rep);
		}

		f = 'MM';
		if ( result.indexOf(f) > -1 ) {
			rep = comPadZero(date.getMonth() + 1, 2);
			result = result.replace(/MM/, rep);
		}

		f = 'ddd';
		if ( result.indexOf(f) > -1 ) {
			rep = yobi[date.getDay()];
			result = result.replace(/ddd/, rep);
		}

		f = 'dd';
		if ( result.indexOf(f) > -1 ) {
			rep = comPadZero(date.getDate(), 2);
			result = result.replace(/dd/, rep);
		}

		f = 'HH';
		if ( result.indexOf(f) > -1 ) {
			rep = comPadZero(date.getHours(), 2);
			result = result.replace(/HH/, rep);
		}

		f = 'mm';
		if ( result.indexOf(f) > -1 ) {
			rep = comPadZero(date.getMinutes(), 2);
			result = result.replace(/mm/, rep);
		}

		f = 'ss';
		if ( result.indexOf(f) > -1 ) {
			rep = comPadZero(date.getSeconds(), 2);
			result = result.replace(/ss/, rep);
		}

		f = 'fff';
		if ( result.indexOf(f) > -1 ) {
			rep = comPadZero(date.getMilliseconds(), 3);
			result = result.replace(/fff/, rep);
		}

		return result;

	}

	/**************************************************
	 * [�@�\]	�����񂩂���t�I�u�W�F�N�g�ɕϊ����܂�	 * [����]	date	���t��\��������
	 * 			format	�t�H�[�}�b�g
	 * [�ߒl]	�ϊ���̓��t�I�u�W�F�N�g
	 **************************************************/
	function comDateParse(date, format){

		var year = 1990;
		var month = 01;
		var day = 01;
		var hour = 00;
		var minute = 00;
		var second = 00;
		var millisecond = 000;

		var f;
		var idx;

		f = 'yyyy';
		idx = format.indexOf(f);
		if ( idx > -1 ) {
			year = date.substr(idx, f.length);
		}

		f = 'MM';
		idx = format.indexOf(f);
		if ( idx > -1 ) {
			month = parseInt(date.substr(idx, f.length), 10) - 1;
		}

		f = 'dd';
		idx = format.indexOf(f);
		if ( idx > -1 ) {
			day = date.substr(idx, f.length);
		}

		f = 'HH';
		idx = format.indexOf(f);
		if ( idx > -1 ) {
			hour = date.substr(idx, f.length);
		}

		f = 'mm';
		idx = format.indexOf(f);
		if ( idx > -1 ) {
			minute = date.substr(idx, f.length);
		}

		f = 'ss';
		idx = format.indexOf(f);
		if ( idx > -1 ) {
			second = date.substr(idx, f.length);
		}

		f = 'fff';
		idx = format.indexOf(f);
		if ( idx > -1 ) {
			millisecond = date.substr(idx, f.length);
		}

		var result = new Date(year, month, day, hour, minute, second, millisecond);

		return result;

	}

	/**************************************************
	 * [�@�\]	�[���p�f�B���O���s���܂�	 * [����]	value	�Ώۂ̕�����
	 * 			length	����
	 * [�ߒl]	���ʕ�����
	 **************************************************/
	function comPadZero(value, length){
	    return new Array(length - ('' + value).length + 1).join('0') + value;
	}
